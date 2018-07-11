function Uninstall-VisualizationSetup {
    <#
    .SYNOPSIS
        Removes up the EUC Monitoring Platform Influx / Grafana platform
    .DESCRIPTION
        Removes the EUC Monitoring Platform Influx / Grafana platform
    .PARAMETER MonitoringPath
        Determines the
    .PARAMETER QuickConfig
        Interactive JSON file creation based on default values
    .INPUTS
        None
    .OUTPUTS
        None
    .NOTES
        Current Version:        1.0
        Creation Date:          19/03/2018
    .CHANGE CONTROL
        Name                    Version         Date                Change Detail
        Hal Lange               1.0             16/04/2018          Initial Creation of Installer
        Adam Yarborough         1.1             11/07/2018          Integration of Hal's work and updating.
    .PARAMETER MonitoringPath
        Folder path to download files needed for monitoring process
    .EXAMPLE
        None Required

    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$MonitoringPath = (get-location)
    )

    begin {
    }

    process {

        #Removing Services
        $NSSM = (get-childitem $MonitoringPath | Where-Object {$_.Name -match 'nssm'}).FullName
        $NSSMEXE = "$nssm\win64\nssm.exe"
        #Remove Grafana Service
        & $nssmexe Stop "Grafana Server"
        & $nssmexe Remove "Grafana Server" confirm
        #Remove Influx Service
        & $nssmexe Stop "InfluxDB Server"
        & $nssmexe Remove "InfluxDB Server" confirm

        #Remove Directories
        Remove-Item -path $MonitoringPath -Recurse

        #Remove Variable
        Remove-Item Env:\Home

        #open FW for Grafana
        Write-Output "Remove Firewall Rules for Grafana and InfluxDB"
        Remove-NetFirewallRule -DisplayName "Grafana Server"
        Remove-NetFirewallRule -DisplayName "InfluxDB Server"
    }

    end {
    }
}