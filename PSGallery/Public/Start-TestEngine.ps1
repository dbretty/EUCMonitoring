function Start-TestEngine {
    <#
.SYNOPSIS
    Starts the main engine behind EUCMonitoring
.DESCRIPTION
    Starts the main engine behind EUCMonitoring
.PARAMETER JSONConfigFilename
    The path to the JSON config file.  
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
        [Parameter(ValueFromPipeline, Mandatory = $true)][string]$JSONConfigFileName
    )

    $Results = @()

    
    if ( test-path $JSONConfigFilename ) {
        $StartTime = (Get-Date)

        try {
            $ConfigObject = Get-Content -Raw -Path $JSONConfigFilename | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            throw "Error reading JSON.  Please Check File and try again."
        }

        foreach ( $Series in $ConfigObject ) {

            # So, this works by iterating over the top elements of the config file and processing them.
            # All checks 
            $SeriesName = $Series.PSObject.Properties.Name
            # As long as its not the global section of the config file
            if ( "Global" -ne $SeriesName ) {
                $SeriesResult = Test-Series $SeriesName $JSONConfigFileName

                if ( $null -ne $SeriesResult ) {
                    if ( "Worker" -eq $SeriesName ) {
                        # Some check to redirect Desktop errors to DesktopErrorFile 
                        # And some for ServerErrorFile
                        foreach ( $Result in $SeriesResult ) {
                            $ResultName = $Result.PSObject.Properties.Name
                            if ( "XdServer" -eq $ResultName ) {
                                "$(get-date) - $SeriesName - $($Result.ComputerName)" | Out-File $ConfigObject.Global.ServerErrorFile -Append
                                $SeriesResult.Errors | Out-File $ConfigObject.Global.ServerErrorFile -Append
                            }
                            elseif ( "XdDesktop" -eq $ResultName ) {
                                "$(get-date) - $SeriesName - $($Result.ComputerName)" | Out-File $ConfigObject.Global.DesktopErrorFile -Append
                                $SeriesResult.Errors | Out-File $ConfigObject.Global.DesktopErrorFile -Append
                            }
                        }
                    }
                    else {
                        foreach ( $Result in $SeriesResult ) {
                            "$(get-date) - $SeriesName - $($Result.ComputerName)" | Out-File $ConfigObject.Global.InfraErrorFile -Append
                            $SeriesResult.Errors | Out-File $ConfigObject.Global.InfraErrorFile -Append
                        }
                    }
                }
                $Results += $SeriesResult
            }
        }

        if ( $ConfigObject.Global.Webdata.Enabled ) {
            New-HTMLReport $ConfigObject $Results 
        }

        # Now we have results.  If we see InfluxDB in ConfigObject, we send results appropriately before
        # returning the object.  This needs to be consistent.  
        if ( $ConfigObject.Global.Influx.Enabled ) {
            Send-ResultToInfluxDB $ConfigObject $Results
        }

        # We want all results to represent the same moment in time, even if that's not true for 
        # collation reasons. This is why this step happens at the end. 


        # Stop the timer and display the output
        $EndTime = (Get-Date)
        Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalSeconds) Seconds"
        Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalMinutes) Minutes"
    }
    else {
        write-error "Path not found to json. Run Set-EUCMonitoring to get started."
    }



}