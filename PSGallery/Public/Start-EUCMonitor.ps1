function Start-EUCMonitor {
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
.CREDITS 
    David Brett - Original creation, Netscaler, Controller, Director, Storefront
    James Kindon - AD, Controller, FAS, PVS, SQL, UPS, WEM
    David Wilkinson - AppV, CC, 
    Ryan Butler - Pretty much everything

.EXAMPLE
    cd "C:\Monitoring"
    Start-EUCMonitor 
    - or - 
    Start-EUCMonitor -JSONConfigFilename "path\to\euc-monitoring.json"

#>
    
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(ValueFromPipeline)][string]$JSONConfigFileName = ("$(get-location)\euc-monitoring.json"),
        [Parameter(ValueFromPipeline)][switch]$OutputToVar
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

        $OutputLocation = $ConfigObject.Global.OutputLocation
        $ServerErrorFile = join-path $OutputLocation $ConfigObject.Global.ServerErrorFile
        $DesktopErrorFile = join-path $OutputLocation $ConfigObject.Global.DesktopErrorFile
        $InfraErrorFile = join-path $OutputLocation $ConfigObject.Global.InfraErrorFile

        Write-Verbose "Testing Output File Location $OutputLocation"

        If ((Test-Path $OutputLocation) -eq $False) {
            try {
                if ( $PSCmdlet.ShouldProcess("ShouldProcess?") ) {
                    Write-Verbose "Output File Location $OutputLocation Does Not Exist - Creating Directory"
                    New-Item -ItemType directory -Path $OutputLocation -ErrorAction Stop        
                }
                else {
                    Write-Verbose "Would create output file location $OutputLocation"
                }
            }
            Catch {
                Write-Error "Could Not Create Output Directory $OutputLocation Quitting"
                break
            } 
        }

        foreach ( $SeriesName in $ConfigObject.PSObject.Properties.Name ) {

            # So, this works by iterating over the top elements of the config file and processing them.
            
            # $SeriesName = $Series.PSObject.Properties.Name
            # As long as its not the global section of the config file
            if ( "Global" -ne $SeriesName ) {
                # XXX CHANGEME XXX 
                # Put in Actual ShouldProcess Checks
                # This is where all the work happens. 
                Write-Verbose "Calling Test-Series $JSONConfigFilename $SeriesName"
                $SeriesResult = Test-Series $JSONConfigFileName $SeriesName

                # As long as we get results, write out any errors to appropriate log file
                if ( $null -ne $SeriesResult ) {

                    foreach ( $Result in $SeriesResult ) {
                        
                        if ( $null -ne $Result.Errors ) {
                            $ResultName = $Result.PSObject.Properties.Name
                    
                            # Check to redirect Desktop errors to DesktopErrorFile 
                            
                            if ( "XdServer" -eq $ResultName ) {
                                "$(get-date) - $SeriesName - $($Result.ComputerName)" | Out-File $ServerErrorFile -Append
                                $SeriesResult.Errors | Out-File $ServerErrorFile -Append
                            }
                            # And some for ServerErrorFile
                            elseif ( "XdDesktop" -eq $ResultName ) {
                                "$(get-date) - $SeriesName - $($Result.ComputerName)" | Out-File $DesktopErrorFile -Append
                                $SeriesResult.Errors | Out-File $DesktopErrorFile -Append
                            } 
                            # Or Just assume its the supporting infrastructure.
                            else {
                                "$(get-date) - $SeriesName - $($Result.ComputerName)" | Out-File $InfraErrorFile -Append
                                $SeriesResult.Errors | Out-File $InfraErrorFile -Append
                            }
                        }
                    }
                }

                $Results += $SeriesResult
            }
        }

        # Now we should have results, even if blank.

        # Output handling
        
        # If we see WebData enabled, send to the report maker.
        if ( $ConfigObject.Global.Webdata.Enabled ) {
            New-HTMLReport $JSONConfigFilename $Results 
        }

        # If we see InfluxDB Enabled in ConfigObject, generate the data.  
        # We want all results to represent the same moment in time, even if that's not true for 
        # collation reasons. This is why this step happens at the end. 
        if ( $ConfigObject.Global.Influx.Enabled ) {
            Send-ResultToInfluxDB $JSONConfigFilename $Results
        }

        # PSGraph generated data, using the State property in each result 
        if ( $ConfigObject.Global.Graph.Enabled ) {
            New-EUCGraph $JSONConfigFilename $Results
        }

        # Maybe console formatted data?  Just ideas at the moment.  
        if ( $ConfigObject.Global.ShowResults.Enabled ) {
            Show-Results $JSONConfigFilename $Results
        }

        # Stop the timer and display the output
        $EndTime = (Get-Date)

        Write-Verbose "Completed."
        Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalMinutes) Minutes"
        Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalSeconds) Seconds"
    }
    else {
        write-error "Path not found to json. Run Set-EUCMonitoring to get started."
    }

    if ( $OutputToVar ) { return $Results }

}