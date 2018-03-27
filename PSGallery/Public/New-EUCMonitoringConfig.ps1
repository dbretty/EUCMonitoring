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
    if ($null -eq $MonitorPath) {
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

    if ($null -eq $OutFile) {
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
    
    #
    # WebData Section.  
    #
    Write-Verbose "Using default output location of $($MyJSONConfig.WebData.outputlocation)"
    Write-Verbose "Using default html output file of $($MyJSONConfig.WebData.htmloutputfile)"
    
    <#
    This is the actual start of the tests.  I'd like it to validate each section for testiing, 
    verify basic connectivity to each host being tested, and leave the default values alone.  
    
    This is a quick config, so we should be having reasonable defaults. 
    #>
    
    #
    # Citrix Section
    #
    $TestCitrix = Read-Host -Prompt 'Would you like to test Citrix (yes/no)'
    if ($TestCitrix -match "y") { 
        $MyJSONConfig.Citrix.global.test = "yes" 
        Write-Verbose "Enabling Citrix monitoring."


        # Citrix / Global Section 
    
        # Get the default Broker Servers. 
        $XDBrokerPrimary = Read-host -Prompt "Primary XenDesktop Broker"
        if ((Connect-Server $XDBrokerPrimary) -ne "Successful") {  
            $Response = Read-Host -Prompt "Unable to connect to $XDBrokerPrimary. Do you want to continue (yes/no)"
            if ($Response -notmatch "y") { return }
        } 
        $MyJSONConfig.Citrix.Global.XDBrokerPrimary = $XDBrokerPrimary

        $XDBrokerFailover = Read-host -Prompt "Failover XenDesktop Broker"
        if ((Connect-Server $XDBrokerFailover) -ne "Successful") {  
            $Response = Read-Host -Prompt "Unable to connect to $XDBrokerFailover. Do you want to continue (yes/no)"
            if ($Response -notmatch "y") { return }
        } 
        $MyJSONConfig.Citrix.Global.XDBrokerFailover = $XDBrokerFailover
        
        # We're going to assume default workloads.  Currently server and desktop. 
        Write-Verbose "Citrix monitoring configured for default workloads."
        # We're going to assume reasonable thresholds for those workloads are configured.
        Write-Verbose "Citrix monitoring configured for default thresholds."


        # Citrix / Xenserver Section
        $TestXenServer = Read-Host -Prompt 'Would you like to monitor Citrix Xenserver (yes/no)'
        if ($TestXenServer -match "y") { 
            $MyJSONConfig.Citrix.Xenserver.test = "yes" 
            Write-Verbose "Enabling Citrix Xenserver monitoring."

            $Poolmasters = (Read-host -Prompt 'Please specify which XenServer pool masters (comma separated)').Replace(' ','')
            $Poolmasters = @($Poolmasters.Split(','))

            foreach ($Poolmaster in $Poolmasters) { 
                if ((Connect-Server $Poolmaster) -ne "Successful") {  
                    $Response = Read-Host -Prompt "Unable to connect to $Poolmaster. Do you want to continue? (yes/no)"
                    if ($Response -notmatch "y") { return }
                } 
            }
            $MyJSONConfig.Citrix.Xenserver.poolmasters = $Poolmasters

            # Should we prompt for username / password in a quick config? For now, no. 
            Write-Verbose "Citrix Xenserver monitoring configured using default values."
            Write-Warning "You need to manually edit $Outfile to put in your username and password."
        }
        else { $MyJSONConfig.Citrix.Xenserver.test = "no" } 


        # Citrix / Storefront Section
        $TestStorefront = Read-Host -Prompt 'Would you like to monitor Citrix Storefront (yes/no)'
        if ($TestStorefront -match "y") { 
            $MyJSONConfig.Citrix.Storefront.test = "yes" 
            Write-Verbose "Enabling Citrix Storefront monitoring"

            $StoreFrontServers = (Read-host -Prompt 'Please specify which Citrix Storefront servers (comma separated)').Replace(' ','')
            $StoreFrontServers = @($StoreFrontServers.Split(','))

            foreach ($StoreFrontServer in $StoreFrontServers) { 
                if ((Connect-Server $StoreFrontServer) -ne "Successful") {  
                    $Response = Read-Host -Prompt "Unable to connect to $StoreFrontServer. Do you want to continue? (yes/no)"
                    if ($Response -notmatch "y") { return }
                } 
            }
            $MyJSONConfig.Citrix.Storefront.StorefrontServers = $StoreFrontServers
            Write-Verbose "Citrix Storefront monitoring configured using default values."
        } 
        else { $MyJSONConfig.Citrix.Storefront.test = "no" }


        # Citrix / Licensing Section 
        $TestLicensing = Read-Host -Prompt '[Citrix] Would you like to test Licensing (yes/no)'
        if ($TestLicensing -match "y") { 
            $MyJSONConfig.Citrix.Licensing.test = "yes" 
            Write-Verbose "Enabling Citrix Licensing Monitoring."
            $LicenseServers = (Read-host -Prompt 'Please specify which Citrix License Servers (comma separated)').Replace(' ','')
            $LicenseServers = @($LicenseServers.Split(','))

            foreach ($Licenseserver in $LicenseServers) { 
                if ((Connect-Server $LicenseServer) -ne "Successful") {  
                    $Response = Read-Host -Prompt "Unable to connect to $LicenseServer. Do you want to continue (yes/no)"
                    if ($Response -notmatch "y") { return }
                } 
            }
            $MyJSONConfig.Citrix.Licensing.LicenseServers = $LicenseServers
            Write-Verbose "Citrix Licensing configured using default values."
        }
        else { $MyJSONConfig.Citrix.Licensing.Test = "no" }
    

        # Citrix / Director Section
        $TestDirector = Read-Host -Prompt 'Would you like to monitor Citrix Director (yes/no)'
        if ($TestDirector -match "y") { 
            $MyJSONConfig.Citrix.Director.Test = "yes" 
            Write-Verbose "Enabling Citrix Director monitoring."
            $DirectorServers = (Read-host -Prompt 'Please specify which Citrix Director Servers (comma separated)').Replace(' ','')
            $DirectorServers = @($DirectorServers.Split(','))

            foreach ($DirectorServer in $DirectorServers) { 
                if ((Connect-Server $DirectorServer) -ne "Successful") {  
                    $Response = Read-Host -Prompt "Unable to connect to $DirectorServer. Do you want to continue (yes/no)"
                    if ($Response -notmatch "y") { return }
                } 
            }
            $MyJSONConfig.Citrix.Director.DirectorServers = $DirectorServers
            Write-Verbose "Citrix Director monitoring configured using default values."
        }
        else { $MyJSONConfig.Citrix.Director.test = "no" }
    

        # Citrix / Controllers Section
        $TestController = Read-Host -Prompt 'Would you like to monitor Citrix Controllers (yes/no)'
        if ($TestController -match "y") { 
            $MyJSONConfig.Citrix.Controllers.Test = "yes" 
            Write-Verbose "Enabling Citrix Controller monitoring."
            $ControllerServers = (Read-host -Prompt 'Please specify which Citrix Controllers (comma separated)').Replace(' ','')
            $ControllerServers = @($ControllerServers.Split(','))

            foreach ($ControllerServer in $ControllerServers) { 
                if ((Connect-Server $ControllerServer) -ne "Successful") {  
                    $Response = Read-Host -Prompt "Unable to connect to $ControllerServer. Do you want to continue (yes/no)"
                    if ($Response -notmatch "y") { return }
                } 
            }
            $MyJSONConfig.Citrix.Controllers.ControllerServers = $ControllerServers
            Write-Verbose "Citrix Controller monitoring configured using default values."
        }
        else { $MyJSONConfig.Citrix.Controllers.test = "no" }
 

        # Citrix / Netscaler Section
        $TestNetscaler = Read-Host -Prompt 'Would you like to monitor Citrix Netscalers (yes/no)'
        if ($TestNetscaler -match "y") { 
            $MyJSONConfig.Citrix.Netscalers.Test = "yes" 
            Write-Verbose "Enabling Citrix Netscaler monitoring."
            $Netscalers = (Read-host -Prompt 'Please specify which Citrix Netscalers by IP (comma separated)').Replace(' ','')
            $Netscalers = @($Netscalers.Split(','))

            foreach ($Netscaler in $Netscalers) { 
                if ((Connect-Server $Netscaler) -ne "Successful") {  
                    $Response = Read-Host -Prompt "Unable to connect to $Netscaler. Do you want to continue (yes/no)"
                    if ($Response -notmatch "y") { return }
                } 
            }
            $MyJSONConfig.Citrix.Netscalers.Netscalers = $Netscalers
            Write-Verbose "Citrix Netscaler monitoring configured using default values."
            Write-Warning "You need to manually edit $Outfile to put in your username and password."
        }
        else { $MyJSONConfig.Citrix.Netscalers.test = "no" }


        # Citrix / Netscaler Gateway Section
        $TestNetscalerGateway = Read-Host -Prompt 'Would you like to monitor the Citrix Netscaler Gateway (yes/no)'
        if ($TestNetscalerGateway -match "y") { 
            $MyJSONConfig.Citrix.NetscalerGateway.Test = "yes" 
            Write-Verbose "Enabling Citrix Netscaler Gateway monitoring."
            $NetscalerGateway = Read-host -Prompt 'Please specify which Citrix Netscaler Gateway by IP'
            
            if ((Connect-Server $NetscalerGateway) -ne "Successful") {  
                $Response = Read-Host -Prompt "Unable to connect to $NetscalerGateway. Do you want to continue (yes/no)"
                if ($Response -notmatch "y") { return }
            } 
            
            $MyJSONConfig.Citrix.NetscalerGateway.NetscalerHostingGateway = $NetscalerGateway
            Write-Verbose "Citrix Netscaler Gateway monitoring configured using default values."
        }
        else { $MyJSONConfig.Citrix.NetscalerGateway.test = "no" }


        # Citrix / Provisioning Server Section
        $TestProvisioningServer = Read-Host -Prompt 'Would you like to monitor Citrix Provisioning Servers (yes/no)'
        if ($TestProvisioningServer -match "y") { 
            $MyJSONConfig.Citrix.ProvisioningServers.Test = "yes" 
            Write-Verbose "Enabling Citrix Provisioning Server monitoring."
            $ProvisioningServers = (Read-host -Prompt 'Please specify which Citrix Provisioning Servers (comma separated)').Replace(' ','')
            $ProvisioningServers = @($ProvisioningServers.Split(','))

            foreach ($ProvisioningServer in $ProvisioningServers) { 
                if ((Connect-Server $ProvisioningServer) -ne "Successful") {  
                    $Response = Read-Host -Prompt "Unable to connect to $ProvisioningServer. Do you want to continue (yes/no)"
                    if ($Response -notmatch "y") { return }
                } 
            }
            $MyJSONConfig.Citrix.ProvisioningServers.ProvisioningServers = $ProvisioningServers
            Write-Verbose "Citrix Provisioning Server monitoring configured using default values."
            Write-Warning "You need to manually edit $Outfile to put in your farm and site names."
        }
        else { $MyJSONConfig.Citrix.ProvisioningServers.test = "no" }


        # Citrix / WEM Section
        $TestWEM = Read-Host -Prompt 'Would you like to monitor Citrix WEM Servers (yes/no)'
        if ($TestWEM -match "y") { 
            $MyJSONConfig.Citrix.WEM.Test = "yes" 
            Write-Verbose "Enabling Citrix WEM Server monitoring."
            $WEMServers = (Read-host -Prompt 'Please specify which Citrix Director Servers (comma separated)').Replace(' ','')
            $WEMServers = @($WEMServers.Split(','))

            foreach ($WEMServer in $WEMServers) { 
                if ((Connect-Server $WEMServer) -ne "Successful") {  
                    $Response = Read-Host -Prompt "Unable to connect to $WEMServer. Do you want to continue (yes/no)"
                    if ($Response -notmatch "y") { return }
                } 
            }
            $MyJSONConfig.Citrix.WEM.WEMServers = $WEMServers
            Write-Verbose "Citrix WEM Servers monitoring configured using default values."
        }
        else { $MyJSONConfig.Citrix.WEM.test = "no" }


        # Citrix / UPS Section
        $TestUPS = Read-Host -Prompt 'Would you like to monitor Citrix UPS Servers (yes/no)'
        if ($TestUPS -match "y") { 
            $MyJSONConfig.Citrix.UPS.Test = "yes" 
            Write-Verbose "Enabling Citrix UPS Server monitoring."
            $UPSServers = (Read-host -Prompt 'Please specify which Citrix Director Servers (comma separated)').Replace(' ','')
            $UPSServers = @($UPSServers.Split(','))

            foreach ($UPSServer in $UPSServers) { 
                if ((Connect-Server $UPSServer) -ne "Successful") {  
                    $Response = Read-Host -Prompt "Unable to connect to $UPSServer. Do you want to continue (yes/no)"
                    if ($Response -notmatch "y") { return }
                } 
            }
            $MyJSONConfig.Citrix.UPS.UPSServers = $UPSServers
            Write-Verbose "Citrix UPS Servers monitoring configured using default values."
        }
        else { $MyJSONConfig.Citrix.UPS.test = "no" }


        # Citrix / FAS Section
        $TestFAS = Read-Host -Prompt 'Would you like to monitor Citrix FAS Servers (yes/no)'
        if ($TestFAS -match "y") { 
            $MyJSONConfig.Citrix.FAS.Test = "yes" 
            Write-Verbose "Enabling Citrix FAS Server monitoring."
            $FASServers = (Read-host -Prompt 'Please specify which Citrix Director Servers (comma separated)').Replace(' ','')
            $FASServers = @($FASServers.Split(','))

            foreach ($FASServer in $FAServers) { 
                if ((Connect-Server $FASServer) -ne "Successful") {  
                    $Response = Read-Host -Prompt "Unable to connect to $FASServer. Do you want to continue (yes/no)"
                    if ($Response -notmatch "y") { return }
                } 
            }
            $MyJSONConfig.Citrix.FAS.FASServers = $FASServers
            Write-Verbose "Citrix FAS Servers monitoring configured using default values."
        }
        else { $MyJSONConfig.Citrix.FAS.test = "no" }


        # Citrix / CC Section
        $TestCC = Read-Host -Prompt 'Would you like to monitor Citrix Cloud Connectors (yes/no)'
        if ($TestCC -match "y") { 
            $MyJSONConfig.Citrix.CC.Test = "yes" 
            Write-Verbose "Enabling Citrix Cloud Connector monitoring."
            $CCServers = (Read-host -Prompt 'Please specify which Citrix Cloud Connectors (comma separated)').Replace(' ','')
            $CCServers = @($CCServers.Split(','))

            foreach ($CCServer in $CCServers) { 
                if ((Connect-Server $CCServer) -ne "Successful") {  
                    $Response = Read-Host -Prompt "Unable to connect to $CCServer. Do you want to continue (yes/no)"
                    if ($Response -notmatch "y") { return }
                } 
            }
            $MyJSONConfig.Citrix.CC.CCServers = $CCServers
            Write-Verbose "Citrix CC Servers monitoring configured using default values."
        }
        else { $MyJSONConfig.Citrix.CC.test = "no" }


        # Citrix / Studio Checks Section
        if ($TestCC -notmatch "y") {
            # This isn't even an option with Cloud Connectors 
            $TestEnvChecks = Read-Host -Prompt 'Would you like to monitor Studio Checks health (yes/no)'
            if ($TestEnvChecks -match "y") {
                $MyJSONConfig.Citrix.EnvChecks.Test = "yes"
                Write-Verbose "Citrix Studio Checks configured using default values."
            }
            else { $MyJSONConfig.Citrix.EnvChecks.test = "no" }
        }


    }
    else { $MyJSONConfig.Citrix.global.test = "no" }


    #
    # Microsoft Section. 
    #
    $TestMicrosoft = Read-Host -Prompt 'Would you like to monitor your Microsoft Resources (yes/no)'
    if ($TestMicrosoft -match "y") { 
        $MyJSONConfig.Microsoft.global.test = "yes" 
        Write-Verbose "Enabling Microsoft Monitoring" 


        # Microsoft / AD
        $TestAD = Read-Host -Prompt 'Would you like to monitor Active Directory (yes/no)'
        if ($TestAD -match "y") { 
            $MyJSONConfig.Microsoft.AD.Test = "yes" 
            Write-Verbose "Enabling Microsoft Active Directory monitoring."
            
            
            # Since this is Quickconfig, let's query based on current scope. 
            # This requires Active Directory module loaded.  Figure out the checks
            <# If module activedirectory available, or loaded#>
            if ( $false ) {
                Write-Verbose "Querying User's domain controllers"
                Import-Module activedirectory
                $ADServers = Get-ADDomainController -filter * | Select-Object -ExpandProperty hostname
            }    
            <# If not... #>
            else {
                $ADServers = (Read-host -Prompt 'Please specify which Domain Controllers (comma separated)').Replace(' ', '')
                $ADServers = @($ADServers.Split(','))

                foreach ($ADServer in $ADServers) { 
                    if ((Connect-Server $ADServer) -ne "Successful") {  
                        $Response = Read-Host -Prompt "Unable to connect to $ADServer. Do you want to continue (yes/no)"
                        if ($Response -notmatch "y") { return }
                    } 
                }
            }
            $MyJSONConfig.Microsoft.AD.ADServers = $ADServers
            Write-Verbose "Microsoft Active Directory monitoring configured using default values."
        }
        else { $MyJSONConfig.Microsoft.AD.test = "no" }

        
        # Microsoft / SQL
        $TestSQL = Read-Host -Prompt 'Would you like to monitor Microsoft MSSQL Servers (yes/no)'
        if ($TestSQL -match "y") { 
            $MyJSONConfig.Microsoft.SQL.Test = "yes" 
            Write-Verbose "Enabling Microsoft MSSQL monitoring."
            $SQLServers = (Read-host -Prompt 'Please specify which MSSQL Servers (comma separated)').Replace(' ','')
            $SQLServers = @($SQLServers.Split(','))

            foreach ($SQLServer in $SQLServers) { 
                if ((Connect-Server $SQLServer) -ne "Successful") {  
                    $Response = Read-Host -Prompt "Unable to connect to $SQLServer. Do you want to continue (yes/no)"
                    if ($Response -notmatch "y") { return }
                } 
            }
            $MyJSONConfig.Microsoft.SQL.SQLServers = $SQLServers
            Write-Verbose "Microsoft SQL Servers monitoring configured using default values."
        }
        else { $MyJSONConfig.Microsoft.SQL.test = "no" }

    }
    else { $MyJSONConfig.Microsoft.global.test = "no" }


      
    # Just a final confirmation so that we will fully run through the configuration before deleting someone's files. 
    if ( (test-path $OutFile) -and ($Force -eq $true) ) {  
        Remove-Item $OutFile
    }

    # Actually output the file. 
    ConvertTo-Json $MyJSONConfig -Depth 4 | Out-File $OutFile

    # This is outputting arrays as space delimited 
    Write-Verbose "All values can be further customized at $($Outfile)"
    Write-Verbose "Done."
}