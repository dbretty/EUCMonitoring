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
    Adam Yarborough         1.0             17/05/2018          Function Creation

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
            
            $SeriesName = $Series.PSObject.Properties.Name
            # As long as its not the global section of the config file
            if ( "Global" -ne $SeriesName ) {

                # This is where all the work happens. 
                $SeriesResult = Test-Series $SeriesName $JSONConfigFileName

                # As long as we get results, write out any errors to appropriate log file
                if ( $null -ne $SeriesResult ) {

                    foreach ( $Result in $SeriesResult ) {
                        
                        if ( $null -ne $Result.Errors ) {
                            $ResultName = $Result.PSObject.Properties.Name
                    
                            # Check to redirect Desktop errors to DesktopErrorFile 
                            
                            if ( "XdServer" -eq $ResultName ) {
                                "$(get-date) - $SeriesName - $($Result.ComputerName)" | Out-File $ConfigObject.Global.ServerErrorFile -Append
                                $SeriesResult.Errors | Out-File $ConfigObject.Global.ServerErrorFile -Append
                            }
                            # And some for ServerErrorFile
                            elseif ( "XdDesktop" -eq $ResultName ) {
                                "$(get-date) - $SeriesName - $($Result.ComputerName)" | Out-File $ConfigObject.Global.DesktopErrorFile -Append
                                $SeriesResult.Errors | Out-File $ConfigObject.Global.DesktopErrorFile -Append
                            } 
                            # Or Just assume its the supporting infrastructure.
                            else {
                                "$(get-date) - $SeriesName - $($Result.ComputerName)" | Out-File $ConfigObject.Global.InfraErrorFile -Append
                                $SeriesResult.Errors | Out-File $ConfigObject.Global.InfraErrorFile -Append
                            }
                        }
                    }
                }
                
                $Results += $SeriesResult
            }
        }

        # Now we should have results, even if blank.

        # If we see WebData enabled, send to the report maker.
        if ( $ConfigObject.Global.Webdata.Enabled ) {
            New-HTMLReport $ConfigObject $Results 
        }

        # If we see InfluxDB Enabled in ConfigObject, generate the data.  
        # We want all results to represent the same moment in time, even if that's not true for 
        # collation reasons. This is why this step happens at the end. 
        if ( $ConfigObject.Global.Influx.Enabled ) {
            Send-ResultToInfluxDB $ConfigObject $Results
        }




        # Stop the timer and display the output
        $EndTime = (Get-Date)
        Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalSeconds) Seconds"
        Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalMinutes) Minutes"
    }
    else {
        write-error "Path not found to json. Run Set-EUCMonitoring to get started."
    }



}