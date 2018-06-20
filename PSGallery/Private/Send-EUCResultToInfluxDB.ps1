          
          
function Send-EUCResultToInfluxDB {
    <#
.SYNOPSIS
    Starts the main engine behind EUCMonitoring
.DESCRIPTION
    Starts the main engine behind EUCMonitoring
.PARAMETER JSONFile
    The path to the JSON config file.  
.NOTES
    Current Version:        1.0
    Creation Date:          07/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough            1.0          17/05/2018          Function Creation
    Adam Yarborough            1.1          18/05/2018          Stoplights checks added to base series
                                                                Cleanup
    Adam Yarborough            1.2          20/06/2018          Added strings as tag support. 
.EXAMPLE
    None Required
#>
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $true)]$JSONFile = ("$(get-location)\euc-monitoring.json"),
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Results
    ) 

    if ( test-path $JSONFile ) {

        try {
            $ConfigObject = Get-Content -Raw -Path $JSONFile | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            throw "Error reading JSON.  Please Check File and try again."
        }

        # We want all results to represent the same moment in time, even if that's not true for 
        # collation reasons. This is why this step happens at the end. 
        $timestamp = Get-InfluxTimestamp
        $InfluxURI = Get-InfluxURI $ConfigObject
         
        Write-Verbose "Pushing results to InfluxDB"
    
        foreach ($SeriesResult in $Results) { 

            $Series = $SeriesResult.Series
            Write-Verbose "Series: $Series"

            foreach ($Result in $SeriesResult.Results) {

                Write-Verbose "Populating results for $($Result.Computername)"
                #This assumes influx doesn't care about the order as long as they're grouped
                # Ports Up
                $ParamString = ""
                foreach ( $Port in $Result.PortsUp ) {
                    if ( $ParamString -eq "" ) { $ParamString = "Port$Port=1" } 
                    else { $ParamString += ",Port$Port=1" }
                }
                foreach ( $Port in $Result.PortsDown ) {
                    if ( $ParamString -eq "" ) { $ParamString = "Port$Port=0" } 
                    else { $ParamString += ",Port$Port=0" }
                }

 
                # This assumes influx doesn't care about the order as long as they're grouped.
                # 1 Means Up, 0 means Down.  
                # Services Up

                foreach ( $Service in $Result.ServicesUp ) {
                    if ( $ParamString -eq "" ) { $ParamString = "$Service=1" } 
                    else { $ParamString += ",$Service=1" }
                }
                foreach ( $Service in $Result.ServicesDown ) {
                    if ( $ParamString -eq "" ) { $ParamString = "$Service=0" } 
                    else { $ParamString += ",$Service=0" }
                }

                #This assumes influx doesn't care about the order as long as they're grouped
                # Checks Up

                foreach ( $Check in $Result.ChecksUp ) {
                    if ( $ParamString -eq "" ) { $ParamString = "$Check=1" } 
                    else { $ParamString += ",$Check=1" }
                }
                foreach ( $Check in $Result.ChecksDown ) {
                    if ( $ParamString -eq "" ) { $ParamString = "$Check=0" } 
                    else { $ParamString += ",$Check=0" }
                }

                # That's all the binary checks.  
                if ( "" -ne $ParamString ) {
                    # Stoplight checks
                    if ( "UP" -eq $Result.State ) { $ParamString += ",State=2" }
                    elseif ( "DEGRADED" -eq $Result.State ) { $ParamString += ",State=1" }
                    else { $ParamString += ",State=0" }

                    $ParamString = $ParamString -replace " ", "\ "
                    $PostParams = "$Series,Server=$($Result.ComputerName) $ParamString $timeStamp"
                    Write-Verbose $PostParams
                    Invoke-RestMethod -Method "POST" -Uri $InfluxUri -Body $postParams
                }

                <# 
                No longer separating the State into a stoplights thing. Just grabbing with the group. 
                $PostParams = "$Series-StopLights,Server=$($Result.ComputerName) $ParamString $timeStamp"
                Invoke-RestMethod -Method "POST" -Uri $InfluxUri -Body $postParams
                #> 

                # Unique Numerical Data will follow
                # ValueName=NumericalValue

                
                foreach ( $CheckData in $Result.ChecksData ) {
                    Write-Verbose "Populating additional check data"
                    
                    $ParamString = "" 
                    $CheckDataName = $CheckData.CheckName
                    $SeriesString = "$Series-$CheckDataName,Server=$($Result.ComputerName)"

                    $CheckData.Values.PSObject.Properties | ForEach-Object {
                        # We take string data as tags.
                        if ($_.Value -is [string]) { $SeriesString += ",$($_.Name)=$($_.Value)" }
                        else {
                            if ( $ParamString -eq "" ) { $ParamString = "$($_.Name)=$($_.Value)" } 
                            else { $ParamString += ",$($_.Name)=$($_.Value)" }
                        }
                    }

                    if ( "" -ne $ParamString ) {
                        $SeriesString = $SeriesString -replace " ", "\ "
                        $ParamString = $ParamString -replace " ", "\ "
                        $PostParams = "$SeriesString $ParamString $timeStamp"
                        Write-Verbose $PostParams
                        Invoke-RestMethod -Method "POST" -Uri $InfluxUri -Body $postParams
                    }
                }
               
            }
        }
    } 
}   
        