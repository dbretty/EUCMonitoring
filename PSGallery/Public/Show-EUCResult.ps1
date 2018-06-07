Function Show-EUCResult {
    <#
.SYNOPSIS
    Console based output
    
.DESCRIPTION
    Console Based output
.PARAMETER Results
    The path to the JSON config file.  
.NOTES
    Current Version:        1.0
    Creation Date:          07/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough            1.0          17/05/2018          Function Creation

.EXAMPLE
    None Required
#>
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Results
    ) 

    # We want all results to represent the same moment in time, even if that's not true for 
    # collation reasons. This is why this step happens at the end. 
    $timeStamp = (get-date)
         
    Write-Verbose "$(ConvertTo-JSON -inputObject $Results -Depth 6)"
    Write-Verbose "Showing results:"
    foreach ($SeriesName in $Results) { 

        $Series = $SeriesName.Series
        Write-Host "--- Series: $Series ---" -ForegroundColor "Cyan"

        foreach ($Result in $SeriesName.Results) {

            # XXX CHANGEME XXX 
            #$Series = "TEMPLATE"
            #This assumes influx doesn't care about the order as long as they're grouped
            # Ports Up
            if ("UP" -eq $Result.State ) { $hostColor = "Green" }
            elseif ( "DEGRADED" -eq $Result.State) { $hostColor = "Yellow" }
            else { $hostColor = "red"}
            Write-Host "Server:   " -NoNewline
            Write-Host "$($Result.ComputerName)" -ForegroundColor $hostColor

            if ( ($Result.PortsUp.Count -gt 0) -or ($Result.PortsDown.Count -gt 0) ) {
                Write-Host "Ports:    " -NoNewline
                foreach ( $Port in $Result.PortsUp ) {
                    Write-Host "$Port " -ForegroundColor "Green" -NoNewline
                }
                foreach ( $Port in $Result.PortsDown ) {
                    Write-Host "$Port " -ForegroundColor "Red" -NoNewline
                }
                Write-Host ""
            }
 
            # This assumes influx doesn't care about the order as long as they're grouped.
            # 1 Means Up, 0 means Down.  
            # Services Up
            if ( ($Result.ServicesUp.Count -gt 0 ) -or ($Result.ServicesDown.Count -gt 0) ) {
                Write-Host "Services: " -NoNewline
                foreach ( $Service in $Result.ServicesUp ) {
                    Write-Host "$Service " -ForegroundColor "Green" -NoNewline
                }
                foreach ( $Service in $Result.ServicesDown ) {
                    Write-Host "$Service " -ForegroundColor "Red" -NoNewline
                }
                Write-Host ""
            }

            #This assumes influx doesn't care about the order as long as they're grouped
            # Checks Up

            if ( ($Result.ChecksUp.Count -gt 0) -or ($Result.ChecksDown.Count -gt 0) ) {
                Write-Host "Checks:   " -NoNewline
                foreach ( $Check in $Result.ChecksUp ) {
                    Write-Host "$Check " -ForegroundColor "Green" -NoNewline
                }
                foreach ( $Check in $Result.ChecksDown ) {
                    Write-Host "$Check " -ForegroundColor "Red" -NoNewline
                }
                Write-Host ""
            }

            # Unique Numerical Data will follow
            # ValueName=NumericalValue
            foreach ( $CheckData in $Result.CheckData ) {
                $ParamString = ""
                
                $CheckDataName = $CheckData.PSObject.Properties.Name
                
                $CheckDataValue = $CheckData.PSObject.Properties.Value
                Write-Verbose "$CheckDataName is $CheckDataValue"
                <#
                Should look like
                Results.Series.ComputerName.CheckData.XdDesktop
                Registered=3
                Unregistered=2
                ...
                #>

                foreach ( $Sub in $CheckDataValue ) {
                    $SubName = $Sub.PSObject.Properties.Value
                    $SubValue = $Sub.PSObject.Properties.Value
                    if ( $ParamString -eq "" ) { $ParamString = "$SubName=$SubValue" } 
                    else { $ParamString += ",$SubName=$SubValue" }
                }

                if ( "" -ne $ParamString ) {
                    $ParamString = $ServiceString -replace " ", "\ "
                    $PostParams = "$Series-$CheckDataName,Server=$($Result.ComputerName) $ParamString $timeStamp"
                    Write-Verbose $PostParams
                    Write-Output $PostParams
                }
            
            }

        }
        Write-Host "`n"
    }
}
