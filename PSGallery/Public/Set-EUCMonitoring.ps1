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
        Folder path to download files needed for monitoring process
    .EXAMPLE
        None Required
    #>
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
        
        Param
        (
            [parameter(Mandatory = $false, ValueFromPipeline = $true)]$MonitoringPath = (get-location) #gets current directory location
        )
    
    
        #New-Item -Path "HKLM:\Software" -Name "EUCMonitoring" -Force
        #New-ItemProperty -Path "HKLM:\Software\EUCMonitoring" -Name "FileLocation" -Value $MonitoringPat
    
    
        if(test-path $MonitoringPath){
            Write-Verbose "Monitoring Directory $MonitoringPath Already Present"
        } else {
            New-Item $MonitoringPath -ItemType Directory
            Write-Verbose "EUC Monitoring Directory Created $MonitoringPath"
        }
    
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        #Files needed to check and downloads
        $filesneeded = @("euc-monitoring.css","euc-monitoring.json.template","euc-monitoring-json-ref.txt")
        
        foreach ($needed in $filesneeded)
        {
            Write-Verbose "Checking for $needed"
            if(test-path "$MonitoringPath\$needed"){
                Write-Verbose "$needed already Present"
            } else {
                Write-Verbose "Pulling $needed"
                Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dbretty/eucmonitoring/master/Package/$needed" -OutFile "$MonitoringPath\$needed"
            }
        }
    
    }