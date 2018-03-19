function Set-EUCMonitoring {
<#
.SYNOPSIS
    Sets up the EUC Monitoring Platform
.DESCRIPTION
    Sets up the EUC Monitoring Platform
.PARAMETER
    None
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
.PARAMETER MonitoringPath
    MonitoringPath
.EXAMPLE
    None Required
#>

    Param
    (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$MonitoringPath
    )

    if($MonitoringPath -eq $null){
        $MonitoringPath = "C:\Monitoring"
    }

    New-Item -Path "HKLM:\Software" -Name "EUCMonitoring" -Force
    New-ItemProperty -Path "HKLM:\Software\EUCMonitoring" -Name "FileLocation" -Value $MonitoringPath
    
    # Get old Verbose Preference and storeit, change Verbose Preference to Continue
    $OldVerbosePreference = $VerbosePreference
    $VerbosePreference = "Continue"

    if(test-path $MonitoringPath){
        Write-Verbose "Monitoring Directory $MonitoringPath Already Present"
    } else {
        New-Item $MonitoringPath -ItemType Directory
        Write-Verbose "EUC Monitoring Directory Created $MonitoringPath"
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Verbose "Pulling euc-monitor.css"
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/dbretty/eucmonitoring/master/Package/euc-monitor.css -OutFile $MonitoringPath\euc-monitor.css
    Write-Verbose "Pulling euc-monitoring-json-ref.txt"
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/dbretty/eucmonitoring/master/Package/euc-monitoring-json-ref.txt -OutFile $MonitoringPath\euc-monitoring-json-ref.txt
    Write-Verbose "Pulling euc-monitoring.json.template"
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/dbretty/eucmonitoring/master/Package/euc-monitoring.json.template -OutFile $MonitoringPath\euc-monitoring.json.template

    # Set the old Verbose Preference back to original value
    $VerbosePreference = $OldVerbosePreference

}
