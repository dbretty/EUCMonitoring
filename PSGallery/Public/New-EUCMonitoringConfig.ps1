function New-EUCMonitoringConfig {
    <#
.SYNOPSIS
    Generates a JSON file for EUC Monitoring based on default values
.DESCRIPTION
    This is a helper utility to create a JSON file for the EUCMonitoring
    platform.  It uses standard ports for defaults.  
.INPUTS
    None
.OUTPUTS
    Creates an eucmonitoring.json file in either current working directory, or 
    via the path supplied.  
.NOTES
    Current Version:        1.0
    Creation Date:          26/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough         1.5.1           26/03/2018          Creation
.PARAMETER MonitorPath
    Path to EUC Monitoring directory. 
.PARAMETER OutFile 
    Path to JSON file for output, manually overriding default. 
.PARAMETER Force
    Overwrite the config file for the Monitor
.EXAMPLE
    None Required
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
        
    param (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$MonitorPath,
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$OutFile,
        [parameter(Mandatory = $false, ValueFromPipeline = $true)][switch]$Force
    )

    Write-Verbose "New-EUCMonitoringConfig Parameter Initialization"
    if ($MonitorPath -eq $null) {
        $MonitorPath = "$(get-location)"
    }
            
    $TemplateFileLocation = "$($MonitorPath)\euc-monitoring.json.template"
    Write-Verbose "Loading template from $($TemplateFileLocation)"
    if (test-path $TemplateFileLocation) {
        $MyJSONConfig = Get-Content -Raw -Path $TemplateFileLocation | ConvertFrom-Json
    }
    else {
        Write-Error "Not a valid path to the EUCMonitoring folder. Run Set-EUCMonitoring to get started."
        Return 
    }

    if ($OutFile -eq $null) {
        $OutFile = "$($MonitorPath)\euc-monitoring.json"
    }
    Write-Verbose "OutFile set to $($Outfile)"

    if (test-path $OutFile) {
        if ($Force -ne $true) {
            Write-Error "The Output File $($OutFile) already exists."
            Write-Error "Please run again with -Force, or specify a specific file with -Outfile <filename>"
            return 
        }
    }
    
    
    <#
    This is the actual start of the tests.  I'd like it to validate each section for testiing, 
    verify basic connectivity to each host being tested, and leave the default values alone.  
    
    This is a quick config, so we should be having reasonable defaults. 
    #>
    $XDBrokerPrimary = Read-host -Prompt "Primary XenDesktop Broker"
    while ((Connect-Server $XDBrokerPrimary) -ne "Successful") {  
        $XDBrokerPrimary = Read-Host -Prompt "Unable to connect to $XDBrokerPrimary. Please enter a valid hostname (Ctrl-C to quit)"
    } 
    $MyJSONConfig.Citrix.Global.XDBrokerPrimary = $XDBrokerPrimary

    # ....

    $TestLicensing = Read-Host -Prompt "Would you like to test Licensing (yes/no)"
    if ($TestLicensing -match "y") { 
        $MyJSONConfig.Citrix.licensing.test = "yes" 
        Write-Verbose ""
        $LicenseServers = Read-host -Prompt "License Servers (comma separated)"
        $LicenseServers = @($LicenseServers.Split(','))

        foreach ($licenseserver in $licenseservers) { 
            if ((Connect-Server $licenseserver) -ne "Successful") {  
                $LicenseServers = Read-Host -Prompt "Unable to connect to $XDBrokerPrimary. Please enter a valid hostname (Ctrl-C to quit)"
                $LicenseServers = @($LicenseServers.Split(','))
            } 
        }
        $MyJSONConfig.Citrix.licensing.licenseServers = $LicenseServers
    }
    else { $MyJSONConfig.Citrix.licensing.test = "no" }
    

    # Just a final confirmation so that we will fully run through the configuration before deleting someone's files. 
    if ( (test-path $OutFile) -and ($Force -eq $true) ) {  
        Remove-Item $OutFile
    }

    # Actually output the file. 
    ConvertTo-Json $MyJSONConfig -Depth 4 | Out-File $OutFile

    # This is outputting arrays as space delimited 
}


