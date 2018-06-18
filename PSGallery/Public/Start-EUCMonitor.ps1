function Start-EUCMonitor {
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
    Adam Yarborough         1.0             17/05/2018          Function Creation
.CREDITS 
    David Brett - Original creation and design, Netscaler, Controller, Director, Storefront, XenServer
    James Kindon - AD, Controller, FAS, PVS, SQL, UPS, WEM
    David Wilkinson - AppV, CC, 
    Ryan Butler - Pretty much everything testing, automation, sanity checks, cleaning 
        up other people's code.  

.EXAMPLE
    cd "C:\Monitoring"
    Start-EUCMonitor 
    - or - 
    Start-EUCMonitor -JSONFile "path\to\euc-monitoring.json"

#>
    
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [ValidateScript( { Test-Path -Type Leaf -Include '*.json' -Path $_ } )]
        [Parameter(ValueFromPipeline)][string]$JSONFile = ("$(get-location)\euc-monitoring.json"),
        [ValidateScript( { Test-Path -Type Leaf -Include '*.css' -Path $_ } )]
        [Parameter(ValueFromPipeline)][string]$CSSFile = ("$(get-location)\euc-monitoring.css"),
        [Parameter(ValueFromPipeline)][string]$LogFile = ("$(get-location)\euc-monitoring.log"),
        [Parameter(ValueFromPipeline)][switch]$OutputToVar
    )
    
    $Results = @()

    $StartTime = (Get-Date)

    try {
        $ConfigObject = Get-Content -Raw -Path $JSONFile | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Error reading JSON.  Please Check File and try again."
    }

    Start-Transcript $LogFile

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

    # Remove the old error files from the system
    If ((Test-Path $ServerErrorFile) -eq $true) { Remove-Item $ServerErrorFile -Force }
    If ((Test-Path $DesktopErrorFile) -eq $true) { Remove-Item $DesktopErrorFile -Force }
    If ((Test-Path $InfraErrorFile) -eq $true) { Remove-Item $InfraErrorFile -Force }

    foreach ( $SeriesName in $ConfigObject.PSObject.Properties.Name ) {

        # So, this works by iterating over the top elements of the config file and processing them.
        # $SeriesName = $Series.PSObject.Properties.Name
        # As long as its not the global section of the config file
        if ( "Global" -ne $SeriesName ) {
            # XXX CHANGEME XXX 
            # Put in Actual ShouldProcess Checks
            # This is where all the work happens. 
            Write-Verbose "Calling Test-Series $JSONFile $SeriesName"
            $SeriesResult = Test-Series $JSONFile $SeriesName

            # As long as we get results, write out any errors to appropriate log file
            if ( $null -ne $SeriesResult ) { 
                $ResultName = $SeriesResult.Series
                foreach ( $Result in $SeriesResult.Results ) {
                    $ComputerName =  $Result.ComputerName
                    if ( $null -ne $Result.Errors ) {
                        foreach ($errorline in $result.Errors) {
                            $ErrorDetails = $errorline
                            $ErrorMessage = "$ResultName - $ComputerName - $ErrorDetails"
                            # Check to redirect Desktop errors to DesktopErrorFile   
                            if ( "XdServer" -eq $ResultName ) {
                                #"$(get-date) - $SeriesName - $($Result.ComputerName)" | Out-File $ServerErrorFile -Append
                                $ErrorMessage | Out-File $ServerErrorFile -Append

                            }
                            # And some for ServerErrorFile
                            elseif ( "XdDesktop" -eq $ResultName ) {
                                #"$(get-date) - $SeriesName - $($Result.ComputerName)" | Out-File $DesktopErrorFile -Append
                                $ErrorMessage | Out-File $DesktopErrorFile -Append
                            } 
                            # Or Just assume its the supporting infrastructure.
                            else {
                                #"$(get-date) - $SeriesName - $($Result.ComputerName)" | Out-File $InfraErrorFile -Append
                                $ErrorMessage | Out-File $InfraErrorFile -Append
                            }
                        }
                    }
                }
                $Results += $SeriesResult
            }                
        }
    }

    # Write-Verbose "$(ConvertTo-JSON -inputObject $Results -Depth 4)"
    # Now we should have results, even if blank.

    # Output handling
        
    # If we see WebData enabled, send to the report maker.
    if ( $ConfigObject.Global.Webdata.Enabled ) {
        New-HTMLReport $JSONFile $CSSFile $Results 
    }

    # If we see InfluxDB Enabled in ConfigObject, generate the data.  
    # We want all results to represent the same moment in time, even if that's not true for 
    # collation reasons. This is why this step happens at the end. 
    if ( $ConfigObject.Global.Influx.Enabled ) {
        Send-EUCResultToInfluxDB -ConfigObject $ConfigObject -Results $Results
    }

    # Maybe console formatted data 
    if ( $ConfigObject.Global.ConsoleResults.Enabled ) {
        Show-EUCResult -Results $Results
    }

    # Stop the timer and display the output
    $EndTime = (Get-Date)

    Write-Verbose "Completed."
    Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalMinutes) Minutes"
    Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalSeconds) Seconds"

    if ( $OutputToVar ) { return $Results }

}