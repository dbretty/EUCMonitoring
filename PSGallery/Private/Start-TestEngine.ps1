function Start-TestEngine {
    <#
.SYNOPSIS
    Tests connectivity to a URL
.DESCRIPTION
    Tests connectivity to a URL
.PARAMETER Url
    The URL to be tested
.NOTES
    Current Version:        1.0
    Creation Date:          07/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             07/02/2018          Function Creation

.EXAMPLE
    None Required
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline, Mandatory=$true)][string]$JSONConfigFileName
    )

    $Results = @()

    if ( $JSONConfigFilename ) {
        $ConfigObject = Get-Content -Raw -Path $JSONConfigFilename | ConvertFrom-Json
    }   
    

    foreach ( $Series in $ConfigObject ) {

        # So, this works by iterating over the top elements of the config file and processing them.
        # All checks 
        $SeriesName = $Series.PSObject.Properties.Name
        # As long as its not the global section of the config file
        if ( "Global" -ne $SeriesName ) {
            $SeriesResult =  Test-Series $SeriesName $JSONConfigFileName
            if ( $null -ne $SeriesResult ) {
                if ( "Worker" -eq $SeriesName ) {
                    # Some check to redirect Desktop errors to DesktopErrorFile 
                    # And some for ServerErrorFile

                }
                else {
                    foreach ( $Result in $SeriesResult ) {
                        "$(get-date) - $SeriesName - $($Result.ComputerName)" | Out-File $ConfigObject.Global.InfraErrorFile -Append
                        $Result.Errors | Out-File $ConfigObject.Global.InfraErrorFile -Append
                    }
                }
            }
        }
    }

    if ( $ConfigObject.Global.Webdata.Enabled ) {
        New-HTMLReport $Results $JSONConfigFileName
    }

    # Now we have results.  If we see InfluxDB in ConfigObject, we send results appropriately before
    # returning the object.  This needs to be consistent.  
    if ( $ConfigObject.Global.Influx.Enabled ) {
        # We want all results to represent the same moment in time, even if that's not true for 
        # collation reasons. This is why this step happens at the end. 
        $timestamp = Get-InfluxTime(get-date)
        $InfluxURI = Get-InfluxURI
         
        foreach ($result in $results) {

            # XXX CHANGEME XXX 
            #$Series = "TEMPLATE"
            #This assumes influx doesn't care about the order as long as they're grouped
            # Ports Up
            $PortString = ""
            foreach ( $Port in $PortsUp ) {
                if ( $PortString -eq "" ) { $PortString = "Port$Port=1" } 
                else { $PortString += ",Port$Port=1" }
            }
            foreach ( $Port in $PortsDown ) {
                if ( $PortString -eq "" ) { $PortString = "Port$Port=0" } 
                else { $PortString += ",Port$Port=0" }
            }

            if ( "" -ne $PortString ) {
                $PortString = $PortString -replace " ", "\ "
                $PostParams = "$Series-Ports,Server=$($Result.ComputerName) $PortString $timeStamp"
                Invoke-RestMethod -Method "POST" -Uri $InfluxUri -Body $postParams
            }
            # This assumes influx doesn't care about the order as long as they're grouped.
            # 1 Means Up, 0 means Down.  
            # Services Up
            $ServiceString = ""
            foreach ( $Service in $ServicesUp ) {
                if ( $ServiceString -eq "" ) { $ServiceString = "$Service=1" } 
                else { $ServiceString += ",$Service=1" }
            }
            foreach ( $Service in $ServicesDown ) {
                if ( $ServiceString -eq "" ) { $ServiceString = "$Service=0" } 
                else { $ServiceString += ",$Service=0" }
            }

            if ( "" -ne $ServiceString ) {
                $ServiceString = $ServiceString -replace " ", "\ "
                $PostParams = "$Series-Services,Server=$($Result.ComputerName) $ServiceString $timeStamp"
                Invoke-RestMethod -Method "POST" -Uri $InfluxUri -Body $postParams
            }    
            #This assumes influx doesn't care about the order as long as they're grouped
            # Checks Up

            $CheckString = ""
            foreach ( $Check in $ChecksUp ) {
                if ( $CheckString -eq "" ) { $CheckString = "$Check=1" } 
                else { $CheckString += ",$Check=1" }
            }
            foreach ( $Service in $ChecksDown ) {
                if ( $CheckString -eq "" ) { $CheckString = "$Check=0" } 
                else { $CheckString += ",$Check=0" }
            }

            $CheckString = $ServiceString -replace " ", "\ "
            $PostParams = "$Series-Checks,Server=$($Result.ComputerName) $ServiceString $timeStamp"
            Invoke-RestMethod -Method "POST" -Uri $InfluxUri -Body $postParams
        }
    }





}