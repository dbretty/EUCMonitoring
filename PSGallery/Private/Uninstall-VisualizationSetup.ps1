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
        Ryan Butler             1.3             24/07/2018          Error and item checking
    .PARAMETER MonitoringPath
        Folder path to download files needed for monitoring process
    .EXAMPLE
        None Required

    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    param (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$MonitoringPath = (get-location)
    )

    begin {
        If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Throw "You must be administrator in order to execute this script"
        }
    }

    process {

        if ($PSCmdlet.ShouldProcess("Remove Visualization Services"))
        {
                #Removing Services
                $Grafana = (get-childitem $MonitoringPath | Where-Object {$_.Name -match 'graf'}).FullName
                $Influx = (get-childitem $MonitoringPath | Where-Object {$_.Name -match 'infl'}).FullName
                $NSSM = (get-childitem $MonitoringPath | Where-Object {$_.Name -match 'nssm'}).FullName

            $NSSMEXE = "$nssm\win64\nssm.exe"
            if (test-path $NSSMEXE)
            {
                #Remove Grafana Service
                Write-Output "Removing Grafana Server service"
                try {
                    & $nssmexe Stop "Grafana Server"}
                catch{
                    Write-Warning $($_.Exception.Message)
                }

                try {
                    & $nssmexe Remove "Grafana Server" confirm
                }
                catch{
                    Write-Warning $($_.Exception.Message)
                }

                #Remove Influx Service
                Write-Output "Removing InfluxDB Server service"
                try {
                    & $nssmexe Stop "InfluxDB Server"
                }
                catch{
                    Write-Warning $($_.Exception.Message)
                }
                
                try {
                    & $nssmexe Remove "InfluxDB Server" confirm
                }
                catch{
                    Write-Warning $($_.Exception.Message)
                }
            }
            else {
                Write-Warning "NSSM.EXE NOT FOUND. Skipping services."
            }
        }
        
        if ($PSCmdlet.ShouldProcess("Remove program directories"))
        {
            #Remove service Directories, all of them.  Scorched earth.
            Write-Output "Removing program directories"
            if(-not ([string]::IsNullOrWhiteSpace($Grafana)))
            {
                Remove-Item -path $Grafana -Recurse
            }
            if(-not ([string]::IsNullOrWhiteSpace($Influx)))
            {
                Remove-Item -path $Influx -Recurse
            }
            if(-not ([string]::IsNullOrWhiteSpace($NSSM)))
            {
                Remove-Item -path $NSSM -Recurse
            }
        }

        #Remove Variable
        if ($PSCmdlet.ShouldProcess("Remove HOME Environment Variable"))
        {
            Write-Output "Removing HOME Environment Variable"
            try{
                Remove-Item Env:\Home -ErrorAction stop
            }
            catch{
                write-warning "Issues removing Influx DB environment variable Home.  Probably already deleted."
            }
        }

        #open FW for Grafana
        if ($PSCmdlet.ShouldProcess("Remove firewall rules"))
        {
            Write-Output "Removing Firewall Rules for Grafana and InfluxDB"
            try {
                Remove-NetFirewallRule -DisplayName "Grafana Server" -ErrorAction stop
            }
            catch{
                Write-Warning $($_.Exception.Message)
            }
            
            try {
                Remove-NetFirewallRule -DisplayName "InfluxDB Server" -ErrorAction stop
            }
            catch {
            Write-Warning $($_.Exception.Message)
            }
        }
    }

    end {
    }
}