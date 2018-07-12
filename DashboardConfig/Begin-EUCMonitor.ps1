
<#
.SYNOPSIS
A small helper script to aide in EUCMonitoring visualization.

.DESCRIPTION
A small helper script to aide in EUCMonitoring visualization, this runs Start-EUCMonitoring in a loop with 
appropriate parameters, with a refresh cycle as determined by your euc-monitoring.jscon config file, which
can be overridden with the Refresh parameter. 

.PARAMETER MonitoringPath
Specific location of your monitoring directory.  Defaults to current location.  

.PARAMETER Refresh
How often Start-EUCMonitoring will be invoked, in seconds.  Defaults to 5 minutes, but can be overridden by 
specifying parameter or by setting Global.Webdata.RefreshDuration in your json config file. 

.PARAMETER JSONFile
Path to your EUCMonitoring JSON config file.

.PARAMETER CSSFile
Path to your EUCMonitoring CSS file.

.PARAMETER LogFile
Path to your EUCMonitoring Log file.  

.EXAMPLE
.\Begin-EUCMonitor.ps1

.EXAMPLE
.\Begin-EUCMonitor.ps1 -Refresh 600

.EXAMPLE
.\Begin-EUCMonitor.ps1 -MonitoringPath 'C:\Monitoring'

.EXAMPLE
.\Begin-EUCMonitor.ps1 -JSONFile .\euc-monitoring.json 

.NOTES
    Current Version:        1.0
    Creation Date:          12/07/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough         1.0             12/07/2018          Initial Creation

#>
[cmdletbinding()]                                                              
Param (
    [parameter(Mandatory = $false, ValueFromPipeline = $true)]$MonitoringPath = (get-location),
    [parameter(Mandatory = $false, ValueFromPipeline = $true)][int]$Refresh,
    [parameter(Mandatory = $false)]$JSONFile,
    [parameter(Mandatory = $false)]$CSSFile,
    [parameter(Mandatory = $false)]$LogFile
)

Import-Module EUCMonitoring

Process {
    if (-not $JSONFile) { $JSONFile = ("$MonitoringPath\euc-monitoring.json") }
    if (-not $CSSFile) { $CSSFile = ("$MonitoringPath\euc-monitoring.css") }
    if (-not $LogFile) { $LogFile = ("$MonitoringPath\euc-monitoring.log") }

    if ( (Test-Path $JSONFile) -eq $False ) { 
        Write-Error "Could not find json config at $JSONFile"
        return
    }
    try {
        $ConfigObject = Get-Content -Raw -Path $JSONFile | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Error reading JSON.  Please Check File and try again."
    }

    # If the user didn't specify a refresh duration, grab from config file.
    if ( -Not $Refresh ) { $Refresh = $ConfigObject.Global.Webdata.RefreshDuration }
    # If the user hasn't specified a refresh duration in the config file, default to 5 minutes. 
    if ( 0 -eq $Refresh) { $Refresh = 300 }

    do { 
        $Params = @{
            JSONFile = $JSONFile
            CSSFile  = $CSSFile
            LogFile  = $LogFile
        }
        Start-EUCMonitor @Params
        Write-Output "You can see current results at http://localhost:3000/ Login: admin/admin"
        Write-Output "Press Ctrl-C to stop.  Sleeping for $Refresh seconds."
        Start-Sleep $Refresh
    } while ($true)
}