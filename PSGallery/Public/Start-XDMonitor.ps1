function Start-XDMonitor {
    <#
.SYNOPSIS
    Monitors the Server Workers
.DESCRIPTION
    Monitors the Server Workers
.PARAMETER
    None
.INPUTS
    None
.OUTPUTS
    None
.NOTES
    Current Version:        1.0
    Creation Date:          07/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             07/02/2018          Script Creation
    David Brett             1.1             20/02/2018          Added Error Checking and Single Ring output
    James Kindon            1.2             15/03/2018          Added Provisioning Server Module
    James Kindon            1.3             17/03/2018          Added WEM, UPS and FAS Modules
    David Brett             1.4             19/03/2018          Added the ability to pull the files location from the registry
    David Wilkinson         1.4.1           19/03/2018          Added Cloud Connector Module
    Adam Yarborough         1.4.2?          19/03/2018          Added Studio Checks
    David Brett             1.5             26/03/2018          Prep For SQL and AD Monitoring
    Adam Yarborough         1.5.1           26/03/2018          Fix Termination of Powershell instance https://git.io/vxEGW
    David Wilkinson         1.6.1           28/03/2018          Added AppV Module
    David Brett             1.6.2           29/03/2018          Moved the Worker checks into a seperate module
.PARAMETER JsonFile
    Path to JSON settings file
.PARAMETER CSSFile
    Path to CSS file for HTML output
.PARAMETER LogFile
    Path to log output file
.PARAMETER OutputToVar
    Outputs to variable VS HTML
.EXAMPLE
    Start-XDMonitor
    Locates euc-monitoring.json, euc-monitoring.css and euc-monitoring.log within the same directory as run command and outputs to html 
.EXAMPLE
    Start-XDMonitor -JsonFile ".\mysettings.json" -LogFile ".\mylog.txt" -CSSFile ".\euc-monitor.css" -Verbose 
    Uses parameters for file paths and outputs to HTML found in JSON
.EXAMPLE
    Start-XDMonitor -outputtovar
    Locates euc-monitoring.json, euc-monitoring.css and euc-monitoring.log within the same directory as run command and outputs results

#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    
    Param
    (        
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$JsonFile = ("$(get-location)\euc-monitoring.json"),
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$CSSFile = ("$(get-location)\euc-monitoring.css"),
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$LogFile = ("$(get-location)\euc-monitoring.log"),
        [parameter(Mandatory = $false, ValueFromPipeline = $true)][switch]$OutputToVar
    )
    
    # Read in the JSON File
    $MyConfigFileLocation = $jsonfile

    if (test-path $MyConfigFileLocation) {

        # Set the script start time
        $StartTime = (Get-Date)

        $MyJSONConfigFile = Get-Content -Raw -Path $MyConfigFileLocation | ConvertFrom-Json
    
        # Start the Transcript
        Start-Transcript $LogFile
    
        # Read in the JSON Data

        # Global Variables
        $XDBrokerPrimary = $MyJSONConfigFile.Citrix.Global.xdbrokerprimary
        $XDBrokerFailover = $MyJSONConfigFile.Citrix.Global.xdbrokerfailover
        # $ControlUp = $MyJSONConfigFile.Citrix.Global.controlup
  
        # Web Data
        # $HTMLData = $MyJSONConfigFile.WebData.htmldatafile
        $HTMLOutput = $MyJSONConfigFile.WebData.htmloutputfile
        $RefreshDuration = $MyJSONConfigFile.WebData.refreshduration
        #$ServerErrorFile = $MyJSONConfigFile.WebData.servererrorfile
        #$DesktopErrorFile = $MyJSONConfigFile.WebData.desktoperrorfile
        #$InfraErrorFile = $MyJSONConfigFile.WebData.infraerrorfile
        #$UpColour = $MyJSONConfigFile.WebData.UpColour
        #$DownColour = $MyJSONConfigFile.WebData.DownColour
        $OutputLocation = $MyJSONConfigFile.WebData.outputlocation
        #$WorkerDonutStroke = $MyJSONConfigFile.WebData.WorkerDonutStroke
        #$WorkerDonutSize = $MyJSONConfigFile.WebData.workerdonutsize
        #$InfraDonutStroke = $MyJSONConfigFile.WebData.InfraDonutStroke
        #$InfraDonutSize = $MyJSONConfigFile.WebData.infradonutsize
        # $WorkerComponents = 1
        # $InfrastructureComponents = 0
        $InfrastructureList = @()

        # Worker Data
        $TestWorkers = $MyJSONConfigFile.Citrix.Worker.test
        #$WorkerTestMode = $MyJSONConfigFile.Citrix.Worker.mode
        #$WorkLoads = $MyJSONConfigFile.Citrix.Worker.workloads
        #$ServerBootThreshold = $MyJSONConfigFile.Citrix.Worker.serverbootthreshold
        #$ServerHighLoad = $MyJSONConfigFile.Citrix.Worker.serverhighload
        #$DesktopBootThreshold = $MyJSONConfigFile.Citrix.Worker.desktopbootthreshold
        #$DesktopHighLoad = $MyJSONConfigFile.Citrix.Worker.desktophighload

        # XenServer Data
        $TestXenServer = $MyJSONConfigFile.Citrix.xenserver.test
        $PoolMasters = $MyJSONConfigFile.Citrix.xenserver.poolmasters
        $ConnectionPort = $MyJSONConfigFile.Citrix.xenserver.poolmasterport
        $XenUserName = $MyJSONConfigFile.Citrix.xenserver.username
        $XenPassword = $MyJSONConfigFile.Citrix.xenserver.password
        $XenPassword = ConvertTo-SecureString $XenPassword -AsPlainText -Force

        # Licensing Data
        $TestLicensing = $MyJSONConfigFile.Citrix.licensing.test
        $LicenseServers = $MyJSONConfigFile.Citrix.licensing.licenseservers
        $VendorDaemonPort = $MyJSONConfigFile.Citrix.licensing.vendordaemonport
        $LicensePort = $MyJSONConfigFile.Citrix.licensing.licenseport
        $WebAdminPort = $MyJSONConfigFile.Citrix.licensing.webadminport
        $SimpleLicensePort = $MyJSONConfigFile.Citrix.licensing.simplelicenseserviceport

        # StoreFront Data
        $TestStoreFront = $MyJSONConfigFile.Citrix.storefront.test
        $StoreFrontServers = $MyJSONConfigFile.Citrix.storefront.storefrontservers
        $StoreFrontPort = $MyJSONConfigFile.Citrix.storefront.storefrontport
        $StoreFrontPath = $MyJSONConfigFile.Citrix.storefront.storefrontpath
        $StoreFrontProtocol = $MyJSONConfigFile.Citrix.storefront.protocol

        # Director Data
        $TestDirector = $MyJSONConfigFile.Citrix.director.test
        $DirectorServers = $MyJSONConfigFile.Citrix.director.directorservers
        $DirectorPort = $MyJSONConfigFile.Citrix.director.directorport
        $DirectorPath = $MyJSONConfigFile.Citrix.director.directorpath
        $DirectorProtocol = $MyJSONConfigFile.Citrix.director.protocol

        # Controller Data
        $TestController = $MyJSONConfigFile.Citrix.controllers.test
        $ControllerServers = $MyJSONConfigFile.Citrix.controllers.controllerservers
        $ControllerPort = $MyJSONConfigFile.Citrix.controllers.controllerport
        $ControllerServices = $MyJSONConfigFile.Citrix.controllers.controllerservices

        # Provisioning Server Data
        $TestProvisioningServer = $MyJSONConfigFile.Citrix.ProvisioningServers.test
        $ProvisioningServers = $MyJSONConfigFile.Citrix.ProvisioningServers.ProvisioningServers
        $ProvisioningServerPort = $MyJSONConfigFile.Citrix.ProvisioningServers.ProvisioningServerport
        $ProvisioningServerServices = $MyJSONConfigFile.Citrix.ProvisioningServers.ProvisioningServerServices

        # NetScaler Data
        $TestNetScaler = $MyJSONConfigFile.Citrix.netscalers.test
        $NetScalers = $MyJSONConfigFile.Citrix.netscalers.netscalers
        $NetScalerUserName = $MyJSONConfigFile.Citrix.netscalers.netscalerusername
        $NetScalerPassword = $MyJSONConfigFile.Citrix.netscalers.netscalerpassword
        $NetScalerPassword = ConvertTo-SecureString $NetScalerPassword -AsPlainText -Force

        # NetScaler Gateway Data
        $TestNetScalerGateway = $MyJSONConfigFile.Citrix.netscalergateway.test
        $NetScalerHostingGateway = $MyJSONConfigFile.Citrix.netscalergateway.netscalerhostinggateway
    
        # Citrix WEM Data
        $TestWEM = $MyJSONConfigFile.Citrix.WEM.test
        $WEMServers = $MyJSONConfigFile.Citrix.WEM.WEMServers
        $WEMAgentServicePort = $MyJSONConfigFile.Citrix.WEM.WEMAgentPort
        $WEMServices = $MyJSONConfigFile.Citrix.WEM.WEMServices

        # Citrix Universal Print Server Data
        $TestUPS = $MyJSONConfigFile.Citrix.UPS.test
        $UPSServers = $MyJSONConfigFile.Citrix.UPS.UPSServers
        $UPSPort = $MyJSONConfigFile.Citrix.UPS.UPSPort
        $UPSServices = $MyJSONConfigFile.Citrix.UPS.UPSServices

        # Citrix Federated Authentication Server Data
        $TestFAS = $MyJSONConfigFile.Citrix.FAS.test
        $FASServers = $MyJSONConfigFile.Citrix.FAS.FASServers
        $FASPort = $MyJSONConfigFile.Citrix.FAS.FASPort
        $FASServices = $MyJSONConfigFile.Citrix.FAS.FASServices
        
        # Citrix Cloud Connector Server Data
        $TestCC = $MyJSONConfigFile.Citrix.CC.test
        $CCServers = $MyJSONConfigFile.Citrix.CC.CCServers
        $CCPort = $MyJSONConfigFile.Citrix.CC.CCPort
        $CCServices = $MyJSONConfigFile.Citrix.CC.CCServices

        # Citrix Environmental Checks
        $TestEnvChecksXD = $MyJSONConfigFile.Citrix.EnvChecks.test
        $EnvChecksXDCheckddc = $MyJSONConfigFile.Citrix.EnvChecks.ddccheck
        $EnvChecksXDCheckdeliverygroup = $MyJSONConfigFile.Citrix.EnvChecks.deliverygroupcheck
        $EnvChecksXDCheckcatalog = $MyJSONConfigFile.Citrix.EnvChecks.catalogcheck
        $EnvChecksXDHypervisor = $MyJSONConfigFile.Citrix.EnvChecks.hypervisorcheck

        # AD Data
        $TestAD = $MyJSONConfigFile.Microsoft.AD.test
        $ADServers = $MyJSONConfigFile.Microsoft.AD.ADServers
        $ADLDAPPort = $MyJSONConfigFile.Microsoft.AD.ADLDAPPort
        $ADServices = $MyJSONConfigFile.Microsoft.AD.ADServices

        # SQL Data
        $TestSQL = $MyJSONConfigFile.Microsoft.SQL.test
        $SQLServers = $MyJSONConfigFile.Microsoft.SQL.SQLServers
        $SQLPort = $MyJSONConfigFile.Microsoft.SQL.SQLPort
        $SQLServices = $MyJSONConfigFile.Microsoft.SQL.SQLServices
        
        # AppV Publishing
        $TestAppV = $MyJSONConfigFile.Microsoft.AppV.test
        $AppVServers = $MyJSONConfigFile.Microsoft.AppV.AppVServers
        $AppVPort = $MyJSONConfigFile.Microsoft.AppV.AppVPort
        $AppVServices = $MyJSONConfigFile.Microsoft.AppV.AppVServices

        <#  THIS CAN ALL BE DELETED RIGHT?
        # Build HTML Output and Error File Full Path
        $ServerErrorFileFullPath = Join-Path -Path $OutputLocation -ChildPath $ServerErrorFile
        $DesktopErrorFileFullPath = Join-Path -Path $OutputLocation -ChildPath $DesktopErrorFile
        $InfraErrorFileFullPath = Join-Path -Path $OutputLocation -ChildPath $InfraErrorFile
        $HTMLFileFullPath = Join-Path -Path $OutputLocation -ChildPath $HTMLOutput
        Write-Verbose "HTML Error File - $ServerErrorFileFullPath"
        Write-Verbose "HTML Error File - $DesktopErrorFileFullPath"
        Write-Verbose "HTML Error File - $InfraErrorFileFullPath"
        Write-Verbose "HTML Output File - $HTMLFileFullPath"

        #Custom PS object
        $results = [pscustomobject]@{}

        # Test the output location and create if not there or clean up old data if exists
        Write-Verbose "Testing Output File Location $OutputLocation"
        If ((Test-Path $OutputLocation) -eq $False) {
            try {
                Write-Verbose "Output File Location $OutputLocation Does Not Exist - Creating Directory"
                New-Item -ItemType directory -Path $OutputLocation -ErrorAction Stop
            }
            Catch {
                Write-Error "Could Not Create Output Directory $OutputLocation Quitting"
                Return # Fix Termination of Powershell instance https://git.io/vxEGW
            } 
        }
        else {
            Write-Verbose "Output File Location $OutputLocation Already Exists, Cleaning Up Old Data"
        
            # Remove Old Error Data File
            Write-Verbose "Deleting Old Error Data File $ServerErrorFileFullPath"
            If (Test-Path $ServerErrorFileFullPath) {
                Remove-Item $ServerErrorFileFullPath
            }

            Write-Verbose "Deleting Old Error Data File $DesktopErrorFileFullPath"
            If (Test-Path $DesktopErrorFileFullPath) {
                Remove-Item $DesktopErrorFileFullPath
            }

            # Remove Old Infrastructure Error Data File
            Write-Verbose "Deleting Old Infrastructure Error Data File $InfraErrorFileFullPath"
            If (Test-Path $InfraErrorFileFullPath) {
                Remove-Item $InfraErrorFileFullPath
            }
        }
        #>

        # Start XD Monitoring Checks
        Write-Verbose "Starting Citrix XD Testing"
        if ($TestWorkers -eq "yes") {
            $InfrastructureList += "XD WorkLoads"
            Write-Verbose "Citrix XD Testing Enabled"
            $results | Add-Member -Name "XenDesktop" -Value (Test-XenDesktop -XDBrokerPrimary $XDBrokerPrimary -XDBrokerFailover $XDBrokerFailover -workerobj $MyJSONConfigFile.Citrix.Worker) -MemberType "NoteProperty"
        }

        # Start Infrastructure Monitoring Checks
        Write-Verbose "Starting Citrix Platform Infrastructure Testing"

        # Checking XenServer
        if ($TestXenServer -eq "yes") {
            # Increment Infrastructure Components
            $InfrastructureList += "XS Pool"
            $InfrastructureList += "XS Host"

            Write-Verbose "XenServer Testing enabled"

            # Test the XenServer Infrastructure
            $results | Add-Member -Name "XenServer" -Value (Test-XenServer -poolmasters $PoolMasters -connectionport $ConnectionPort -errorfile $InfraErrorFileFullPath -xenusername $XenUserName -xenpassword $XenPassword) -MemberType "NoteProperty"
        }

        # Checking Licensing
        if ($TestLicensing -eq "yes") {
            # Increment Infrastructure Components
            $InfrastructureList += "Licensing"

            Write-Verbose "Citrix Licensing Testing enabled"

            $results | Add-Member -Name "Licensing" -Value (Test-Licensing -licenseservers $LicenseServers -VendorDaemonPortString $VendorDaemonPort -licenseportstring $LicensePort -webadminportstring $WebAdminPort -SimpleLicenseServicePortString $SimpleLicensePort -errorfile $InfraErrorFileFullPath) -MemberType "NoteProperty"
        }
  
        # Checking StoreFront
        if ($TestStoreFront -eq "yes") {
            # Increment Infrastructure Components
            $InfrastructureList += "StoreFront"

            Write-Verbose "StoreFront Testing enabled"

            # Test the StoreFront Infrastructure
            $results | Add-Member -Name "StoreFront" -Value (Test-StoreFront -StoreFrontServers $StoreFrontServers -StoreFrontPortString $StoreFrontPort -StoreFrontPath $StoreFrontPath -StoreFrontProtocol $StoreFrontProtocol -ErrorFile $InfraErrorFileFullPath) -MemberType "NoteProperty"
        }

        # Checking Director
        if ($TestDirector -eq "yes") {
            # Increment Infrastructure Components
            $InfrastructureList += "Director"

            Write-Verbose "Director Testing enabled"

            # Test the Director Infrastructure
            $results | Add-Member -Name "Director" -Value (Test-Director -DirectorServers $DirectorServers -DirectorPortString $DirectorPort -DirectorPath $DirectorPath -DirectorProtocol $DirectorProtocol -ErrorFile $InfraErrorFileFullPath) -MemberType "NoteProperty"
        }

        # Checking Controllers
        if ($TestController -eq "yes") {
            # Increment Infrastructure Components
            $InfrastructureList += "Controller"

            Write-Verbose "Controller Testing enabled"

            # Test the StoreFront Infrastructure
            $results | Add-Member -Name "Controller" -Value (Test-Controller -Controllers $ControllerServers -ControllerPortString $ControllerPort -ControllerServices $ControllerServices -ErrorFile $InfraErrorFileFullPath) -MemberType "NoteProperty"
        }

        # Checking Provisioning Servers
        if ($TestProvisioningServer -eq "yes") {
            # Increment Infrastructure Components
            $InfrastructureList += "PVS"

            Write-Verbose "Provisioning Server Testing enabled"

            # Test the Provisioning Server Infrastructure
            $results | Add-Member -Name "PVS" -Value (Test-ProvisioningServer -ProvisioningServers $ProvisioningServers -ProvisioningServerPortString $ProvisioningServerPort -ProvisioningServerServices $ProvisioningServerServices -ErrorFile $InfraErrorFileFullPath) -MemberType "NoteProperty"
        }

        # Checking NetScaler
        if ($TestNetScaler -eq "yes") {
            # Increment Infrastructure Components
            $InfrastructureList += "NetScaler"
            $InfrastructureList += "Load Balancer"

            Write-Verbose "NetScaler Testing enabled"

            # Test the NetScaler Infrastructure
            $results | Add-Member -Name "NetScaler" -Value (Test-NetScaler -NetScalers $NetScalers -UserName $NetScalerUserName -Password $NetScalerPassword -ErrorFile $InfraErrorFileFullPath) -MemberType "NoteProperty"
        }

        # Checking NetScaler Gateway
        if ($TestNetScalerGateway -eq "yes") {
            $InfrastructureList += "NS Gateway"
            Write-Verbose "NetScaler Gateway Testing enabled"    
            $results | Add-Member -Name "NetScalerGateway" -Value (Test-NetscalerGateway -NetScalerHostingGateway $NetScalerHostingGateway -NetscalerUserName $NetScalerUserName -netscalerpassword $NetscalerPassword) -MemberType "NoteProperty"
        }
    
        # Checking WEM Servers
        if ($TestWEM -eq "yes") {
            # Increment Infrastructure Components
            $InfrastructureList += "WEM"

            Write-Verbose "Citrix WEM Server Testing enabled"

            # Test the Workspace Environment Management Infrastructure
            $results | Add-Member -Name "WEM" -Value (Test-WEM -WEMServers $WEMServers -WEMAgentPortString $WEMAgentServicePort -WEMServices $WEMServices -ErrorFile $InfraErrorFileFullPath) -MemberType "NoteProperty"
        }

        # Checking Citrix Universal Print Servers
        if ($TestUPS -eq "yes") {
            # Increment Infrastructure Components
            $InfrastructureList += "UPS"

            Write-Verbose "Citrix Universal Print Server Testing enabled"

            # Test the Universal Print Server Infrastructure
            $results | Add-Member -Name "UPS" -Value (Test-UPS -UPSServers $UPSServers -UPSPortString $UPSPort -UPSServices $UPSServices -ErrorFile $InfraErrorFileFullPath) -MemberType "NoteProperty"
        }

        # Checking Citrix Federated Authentication Servers
        if ($TestFAS -eq "yes") {
            # Increment Infrastructure Components
            $InfrastructureList += "FAS"

            Write-Verbose "Federated Authentication Server Testing enabled"

            # Test the Federated Authentication Server Infrastructure
            $results | Add-Member -Name "FAS" -Value (Test-FAS -FASServers $FASServers -FASPortString $FASPort -FASServices $FASServices -ErrorFile $InfraErrorFileFullPath) -MemberType "NoteProperty"
        }

        # Checking Cloud Connector Servers
        if ($TestCC -eq "yes") { 
            # Increment Infrastructure Components
            $InfrastructureList += "CC"

            Write-Verbose "Citrix Cloud Connector Server Testing enabled"

            # Test the Cloud Connector Server Infrastructure
            $results | Add-Member -Name "CC" -Value (Test-CC -CCServers $CCServers -CCPortString $CCPort -CCServices $CCServices -ErrorFile $InfraErrorFileFullPath) -MemberType "NoteProperty"
        }
        
        if (($TestEnvChecksXD -eq "yes") -and ($TestCC -eq "no")) {
            # Increment Infrastructure Components
            $InfrastructureList += "EnvCheck"

            Write-Verbose "Citrix Environmental Checks Testing enabled"

            # Test the Citrix Environmental Checks
            $results | Add-Member -Name "EnvCheck" -Value (Test-EnvChecksXD -AdminAddress $Broker -ErrorFile $InfraErrorFileFullPath -DDCcheck $EnvChecksXDCheckddc -DeliveryGroupCheck $EnvChecksXDCheckdeliverygroup -CatalogCheck $EnvChecksXDCheckcatalog -HypervisorCheck $EnvChecksXDHypervisor) -MemberType "NoteProperty"
        }

        # Checking Active Directory Servers
        if ($TestAD -eq "yes") {
            # Increment Infrastructure Components
            $InfrastructureList += "AD"

            Write-Verbose "Active Directory Server Testing enabled"

            # Test Active Directory Infrastructure
            $results | Add-Member -Name "AD" -Value (Test-AD -adserver $ADServers -adportstring $ADLDAPPort -adservices $ADServices -errorfile $InfraErrorFileFullPath) -MemberType "NoteProperty"
        }

        # Checking SQL Servers
        if ($TestSQL -eq "yes") {
            # Increment Infrastructure Components
            $InfrastructureList += "SQL"
    
            Write-Verbose "SQL Server Testing enabled"
    
            # Test SQL Infrastructure
            $results | Add-Member -Name "SQL" -Value (Test-SQL -SQLServers $SQLServers -SQLPortString $SQLPort -SQLServices $SQLServices -ErrorFile $InfraErrorFileFullPath) -MemberType "NoteProperty"
        }    
               
        
        # Checking AppV Servers
        if ($TestAppv -eq "yes") { 
            # Increment Infrastructure Components
            $InfrastructureList += "AppV"

            Write-Verbose "AppV Publishing Servers Testing enabled"

            # Test the AppV Publishing Server Infrastructure
            $results | Add-Member -Name "AppV" -Value (Test-AppV -AppVServers $AppVServers -AppVPortString $AppVPort -AppVServices $AppVServices -ErrorFile $InfraErrorFileFullPath) -MemberType "NoteProperty"
        }

        # Add the infrastructure list to the object
        $results | Add-Member -Name "InfrastructureList" -Value $InfrastructureList -MemberType "NoteProperty"
        
        
        if ($OutputToVar) {
            return $results
        }
        else {   
            # Build the HTML output file
            # THIS DOESN"T ACTUALLY WORK YET
            # Need to pass int he object and sort out the code
            # New-HTMLReport $HTMLOutput $OutputLocation $InfrastructureComponents $InfrastructureList $WorkLoads $CSSFile $RefreshDuration
            New-HTMLReport -HTMLOutputFile $HTMLOutput -HTMLOutputLocation $OutputLocation -EUCMonitoring $Results -CSSFile $CSSFile -RefreshDuration $RefreshDuration
        }
        
        # Stop the timer and display the output
        $EndTime = (Get-Date)
        Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalSeconds) Seconds"
        Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalMinutes) Minutes"
    }
    else {
        write-error "Path not found to json. Run Set-EUCMonitoring to get started."
    }

    }

