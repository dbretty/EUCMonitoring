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
        Adam Yarborough         1.2             12/07/2018          Remove only Grafana, Influx, and NSSM 
                                                                    items from $MonitoringPath
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
        If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Throw "You must be administrator in order to execute this script"
        }
    }

    process {

        #Removing Services
        $Grafana = (get-childitem $MonitoringPath | Where-Object {$_.Name -match 'graf'}).FullName
        $Influx = (get-childitem $MonitoringPath | Where-Object {$_.Name -match 'infl'}).FullName
        $NSSM = (get-childitem $MonitoringPath | Where-Object {$_.Name -match 'nssm'}).FullName

        <#if ( ($null -eq $Grafana) -or ($null -ne $Influx ) -or ($null -ne $NSSM ) ) {
            Write-Warning "Unable to confirm all components for uninstall in $MonitoringPath"
            Write-Warning "Grafana: $Grafana"
            Write-Warning "Influx: $Influx"
            Write-Warning "NSSM: $NSSM"
            return
        }
        #>
        $NSSMEXE = "$nssm\win64\nssm.exe"
        #Remove Grafana Service
        Write-Output "Removing Grafana Server service"
        & $nssmexe Stop "Grafana Server"
        & $nssmexe Remove "Grafana Server" confirm
        #Remove Influx Service
        Write-Output "Removing InfluxDB Server service"
        & $nssmexe Stop "InfluxDB Server"
        & $nssmexe Remove "InfluxDB Server" confirm

        #Remove service Directories, all of them.  Scorched earth.
        Write-Output "Removing program directories"
        Remove-Item -path $Grafana -Recurse 
        Remove-Item -path $Influx -Recurse 
        Remove-Item -path $NSSM -Recurse

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