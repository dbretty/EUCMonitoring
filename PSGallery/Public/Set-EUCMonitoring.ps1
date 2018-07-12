function Set-EUCMonitoring {
    <#
    .SYNOPSIS
        Sets up the EUC Monitoring Platform
    .DESCRIPTION
        Sets up the EUC Monitoring Platform
    .PARAMETER MonitoringPath
        Determines the location of the EUCMonitoring configuration.
    .PARAMETER InstallVisualizationSetup
        Downloads and installs InfluxDB, Grafana, and NSSM into the MonitoringPath locaiton.  Creates services,
        and opens up local firewall rules. Installs default EUC dashboards. Requires internet accessibility.  
        internet connection.  
    .PARAMETER UninstallVisualizationSetup
        Removes local instances of InfluxDB, Grafana and NSSM as installed in the MonitoringPath. Removes the
        created Services, closes firewall rules. 
    .INPUTS
        None
    .OUTPUTS
        None
    .NOTES
        Current Version:        1.0
        Creation Date:          19/03/2018
    .CHANGE CONTROL
        Name                    Version         Date                Change Detail
        David Brett             1.0             19/03/2018          Script Creation
        Adam Yarborough         1.1             27/03/2018          Feature Request: Add Quick Config https://git.io/vxz4I
        David Brett             1.2             26/06/2018          Cleaned up the Function and removed old code
        Adam Yarborough         1.3             11/07/2018          Integration of visualization installer/uninstaller.
    .PARAMETER MonitoringPath
        Folder path to download files needed for monitoring process
    .EXAMPLE
        None Required
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]

    Param
    (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$MonitoringPath = (get-location), #gets current directory location
        #        [parameter(Mandatory = $false, ValueFromPipeline = $true)][switch]$QuickConfig # Determines if they need a walkthrough.
        [parameter(Mandatory = $false, ValueFromPipeline = $true)][switch]$InstallVisualizationSetup,
        [parameter(Mandatory = $false, ValueFromPipeline = $true)][switch]$UninstallVisualizationSetup
    )

    if ( test-path $MonitoringPath ) {
        Write-Verbose "Monitoring Directory $MonitoringPath Already Present"
    }
    else {
        New-Item $MonitoringPath -ItemType Directory
        Write-Verbose "EUC Monitoring Directory Created $MonitoringPath"
    }

    # Uninstall and exit. 
    if ( $UninstallVisualizationSetup -eq $true ) {
        Uninstall-VisualizationSetup -MonitoringPath $MonitoringPath
        return
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    #Files needed to check and downloads
    $filesneeded = @("euc-monitoring.css", "euc-monitoring.json.template", "euc-monitoring-json-ref.txt")

    foreach ( $needed in $filesneeded ) {
        Write-Verbose "Checking for $needed"
        if ( test-path "$MonitoringPath\$needed" ) {
            Write-Verbose "$needed already Present"
        }
        else {
            Write-Verbose "Pulling $needed"
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dbretty/eucmonitoring/master/Package/$needed" -OutFile "$MonitoringPath\$needed"
        }
    }

    # Feature Request: Add Quick Config https://git.io/vxz4I
    if ( $QuickConfig -eq $true ) {
        New-EUCMonitoringConfig -MonitorPath $MonitoringPath
    }

    if ( $InstallVisualizationSetup -eq $true ) {
        Install-VisualizationSetup -MonitoringPath $MonitoringPath

    }
    
}