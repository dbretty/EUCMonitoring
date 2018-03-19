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
.PARAMETER RootDirectory
    RootDirectory
.EXAMPLE
    None Required
#>

    Param
    (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$RootDirectory
    )

if($RootDirectory -eq $null) {
    $RootDirectory = Get-ItemPropertyValue -Path "HKLM:\Software\EUCMonitoring" -Name "FileLocation"
}

# Get old Verbose Preference and storeit, change Verbose Preference to Continue
$OldVerbosePreference = $VerbosePreference
$VerbosePreference = "Continue"

# Set Log file location
$Log = "${env:SystemRoot}" + "\Temp\euc-monitoring.log"
    
# Read in the JSON File
$MyConfigFileLocation = ("$RootDirectory\euc-monitoring.json")

if (test-path $MyConfigFileLocation) {

    # Set the script start time
    $StartTime = (Get-Date)

    $MyJSONConfigFile = Get-Content -Raw -Path $MyConfigFileLocation | ConvertFrom-Json
    
    # Start the Transcript
    Start-Transcript $Log
    
    # Read in the JSON Data

    # Global Variables
    $XDBrokerPrimary = $MyJSONConfigFile.Citrix.Global.xdbrokerprimary
    $XDBrokerFailover = $MyJSONConfigFile.Citrix.Global.xdbrokerfailover
    $WorkLoads = $MyJSONConfigFile.Citrix.Global.workloads
    $ControlUp = $MyJSONConfigFile.Citrix.Global.controlup
  
    # Web Data
    $HTMLData = $MyJSONConfigFile.WebData.htmldatafile
    $HTMLOutput = $MyJSONConfigFile.WebData.htmloutputfile
    $ServerErrorFile = $MyJSONConfigFile.WebData.servererrorfile
    $DesktopErrorFile = $MyJSONConfigFile.WebData.desktoperrorfile
    $InfraErrorFile = $MyJSONConfigFile.WebData.infraerrorfile
    $UpColour = $MyJSONConfigFile.WebData.UpColour
    $DownColour = $MyJSONConfigFile.WebData.DownColour
    $OutputLocation = $MyJSONConfigFile.WebData.outputlocation
    $WorkerDonutStroke = $MyJSONConfigFile.WebData.WorkerDonutStroke
    $WorkerDonutSize = $MyJSONConfigFile.WebData.workerdonutsize
    $InfraDonutStroke = $MyJSONConfigFile.WebData.InfraDonutStroke
    $InfraDonutSize = $MyJSONConfigFile.WebData.infradonutsize
    $WorkerComponents = 1
    $InfrastructureComponents = 0
    $InfrastructureList = @()

    # XenServer Data
    $TestXenServer = $MyJSONConfigFile.Citrix.xenserver.test
    $PoolMasters = $MyJSONConfigFile.Citrix.xenserver.poolmasters
    $ConnectionPort = $MyJSONConfigFile.Citrix.xenserver.poolmasterport
    $XenUserName = $MyJSONConfigFile.Citrix.xenserver.username
    $XenPassword = $MyJSONConfigFile.Citrix.xenserver.password

    # StoreFront Data
    $TestStoreFront = $MyJSONConfigFile.Citrix.storefront.test
    $StoreFrontServers = $MyJSONConfigFile.Citrix.storefront.storefrontservers
    $StoreFrontPort = $MyJSONConfigFile.Citrix.storefront.storefrontport
    $StoreFrontPath = $MyJSONConfigFile.Citrix.storefront.storefrontpath
    $StoreFrontProtocol = $MyJSONConfigFile.Citrix.storefront.protocol

    # Licensing Data
    $TestLicensing = $MyJSONConfigFile.Citrix.licensing.test
    $LicenseServers = $MyJSONConfigFile.Citrix.licensing.licenseservers
    $VendorDaemonPort = $MyJSONConfigFile.Citrix.licensing.vendordaemonport
    $LicensePort = $MyJSONConfigFile.Citrix.licensing.licenseport
    $WebAdminPort = $MyJSONConfigFile.Citrix.licensing.webadminport
    $SimpleLicensePort = $MyJSONConfigFile.Citrix.licensing.simplelicenseserviceport

    # Director Data
    $TestDirector = $MyJSONConfigFile.Citrix.director.test
    $DirectorServers = $MyJSONConfigFile.Citrix.director.directorervers
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
    $ProvisioningServerFarm = $MyJSONConfigFile.Citrix.ProvisioningServers.ProvisioningServerFarm
    $ProvisioningServerSite = $MyJSONConfigFile.Citrix.ProvisioningServers.ProvisioningServerSite
    $ProvisioningServers = $MyJSONConfigFile.Citrix.ProvisioningServers.ProvisioningServers
    $ProvisioningServerPort = $MyJSONConfigFile.Citrix.ProvisioningServers.ProvisioningServerport
    $ProvisioningServerServices = $MyJSONConfigFile.Citrix.ProvisioningServers.ProvisioningServerServices

    # NetScaler Data
    $TestNetScaler = $MyJSONConfigFile.Citrix.netscalers.test
    $NetScalers = $MyJSONConfigFile.Citrix.netscalers.netscalers
    $NetScalerUserName = $MyJSONConfigFile.Citrix.netscalers.netscalerusername
    $NetScalerPassword = $MyJSONConfigFile.Citrix.netscalers.netscalerpassword

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

    # Build HTML Output and Error File Full Path
    $ServerErrorFileFullPath = Join-Path -Path $OutputLocation -ChildPath $ServerErrorFile
    $DesktopErrorFileFullPath = Join-Path -Path $OutputLocation -ChildPath $DesktopErrorFile
    $InfraErrorFileFullPath = Join-Path -Path $OutputLocation -ChildPath $InfraErrorFile
    $HTMLFileFullPath = Join-Path -Path $OutputLocation -ChildPath $HTMLOutput
    Write-Verbose "HTML Error File - $ServerErrorFileFullPath"
    Write-Verbose "HTML Error File - $DesktopErrorFileFullPath"
    Write-Verbose "HTML Error File - $InfraErrorFileFullPath"
    Write-Verbose "HTML Output File - $HTMLFileFullPath"

    # Test the output location and create if not there or clean up old data if exists
    Write-Verbose "Testing Output File Location $OutputLocation"
    If ((Test-Path $OutputLocation) -eq $False) {
        try {
            Write-Verbose "Output File Location $OutputLocation Does Not Exist - Creating Directory"
            New-Item -ItemType directory -Path $OutputLocation -ErrorAction Stop
        }
        Catch {
            Write-Verbose "Could Not Create Output Directory $OutputLocation Quitting"
            Exit
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

    # Display the XenDesktop Brokers Passed In
    Write-Verbose "XenDexktop Primary Broker $XDBrokerPrimary"
    Write-Verbose "XenDesktop Failover Broker $XDBrokerFailover"

    # Load the Citrix Broker Powershell SDK
    $ctxsnap = add-pssnapin citrix*
    $ctxsnap = get-pssnapin citrix*

    if ($ctxsnap -eq $null) {
        Write-Verbose "XenDesktop Powershell Snapin Load Failed - No XenDesktop Brokering SDK Found"
        # Remove Global Functions File
        remove-module xendesktop-monitor-global
        Write-Verbose "Cannot Load XenDesktop Powershell SDK"
        Exit
    }
    else {
        Write-Verbose "XenDesktop Powershell SDK Snapin Loaded"
    }

    # Test the primary broker for connectivity and set global broker vairable is good, if not fail over to the secondary
    if ((Connect-Server $XDBrokerPrimary) -eq "Successful") {
        $Broker = $XDBrokerPrimary
    }
    else {
        if ((Connect-Server $XDBrokerFailover) -eq "Successful") {
            $Broker = $XDBrokerFailover
        }
        else {
            Write-Verbose "Cannot connect to any of the configured brokers - quitting"
            # Remove Global Functions File
            remove-module xendesktop-monitor-global
            Write-Verbose "Cannot Connect to XenDesktop Brokers $XDBrokerPrimary or $XDBrokerFailover"
            Exit
        }
    }
    Write-Verbose "Configured XenDesktop Broker for Connectivity: $Broker"

    # Split The Workloads Into An Array and Loop Script Through Them
    $WorkLoadArray = $WorkLoads -Split ","
    foreach ($Workload in $WorkLoadArray) {
        
        # Increment Worker Components
        $WorkerComponents++

        if ($Workload -eq "server") {
            $ErroFileFullPath = $ServerErrorFileFullPath
        }
        else {
            $ErroFileFullPath = $DesktopErrorFileFullPath
        }
       
        # Workload Data
        $BootThreshold = $MyJSONConfigFile.$WorkLoad.bootthreshold
        $DonutFile = $MyJSONConfigFile.$WorkLoad.donutfile
        $HighLoad = $MyJSONConfigFile.$Workload.highload

        # Build Full File Paths
        $HTMLDataFullPath = Join-Path -Path $OutputLocation -ChildPath "$WorkLoad-$HTMLData"
        $DonutFullPath = Join-Path -Path $OutputLocation -ChildPath "$WorkLoad-$DonutFile"
        Write-Verbose "HTML Data File - $HTMLDataFullPath"
        Write-Verbose "Server Donut File - $DonutFullPath"

        # Remove Old HTML Data File
        Write-Verbose "Deleting Old HTML Data File $HTMLDataFullPath"
        If (Test-Path $HTMLDataFullPath) {
            Remove-Item $HTMLDataFullPath
        }

        # Remove Old Donut File
        Write-Verbose "Deleting Old Donut File $DonutFullPath"
        If (Test-Path $DonutFullPath) {
            Remove-Item $DonutFullPath
        }

        # Get Delivery Groups and Maintenance Mode Details
        Write-Verbose "Querying Delivery Group Maintenance Mode Details"

        # Get Full List Of Delivery Groups
        Write-Verbose "Getting Delivery Groups for Type - $WorkLoad"
        if ($Workload -eq "server") {
            $DeliveryGroups = Get-BrokerDesktopGroup -AdminAddress $Broker | Where-Object {$_.SessionSupport -eq "MultiSession"} | Select PublishedName, InMaintenanceMode
            $TotalConnectedUsers = (((get-brokersession -MaxRecordCount 5000) | where-object {$_.DesktopKind -eq "Shared" -and $_.SessionState -eq "Active"}) | measure).Count
            $TotalUsersDisconnected = (((get-brokersession -MaxRecordCount 5000) | where-object {$_.DesktopKind -eq "Shared" -and $_.SessionState -ne "Active"}) | measure).Count
        }
        else {
            $DeliveryGroups = Get-BrokerDesktopGroup -AdminAddress $Broker | Where-Object {$_.SessionSupport -eq "SingleSession"} | Select PublishedName, InMaintenanceMode
            $TotalConnectedUsers = (((get-brokersession -MaxRecordCount 5000) | where-object {$_.DesktopKind -ne "Shared" -and $_.SessionState -eq "Active"}) | measure).Count
            $TotalUsersDisconnected = (((get-brokersession -MaxRecordCount 5000) | where-object {$_.DesktopKind -ne "Shared" -and $_.SessionState -ne "Active"}) | measure).Count
        }
        "Total User Base,$TotalConnectedUsers,$TotalUsersDisconnected" | Out-File $HTMLDataFullPath -Append

        # Work out the number of Delivery Groups in Maintenance Mode and write them back to the HTML Data File
        $DGFullCount = ($DeliveryGroups | Measure).Count
        $DGMaintenanceCount = ($DeliveryGroups | Where-Object {$_.InMaintenanceMode -match "True"} | Measure).Count
        $DGNonMaintenanceCount = ($DeliveryGroups | Where-Object {$_.InMaintenanceMode -match "False"} | Measure).Count
        Write-Verbose "Total Number of Delivery Groups: $DGFullCount"
        Write-Verbose "Total Number of Delivery Groups in Maintenance Mode: $DGMaintenanceCount"
        Write-Verbose "Total Number of Delivery Groups in Available Status: $DGNonMaintenanceCount"
        Write-Verbose "Writing Delivery Group Maintenance Mode Details to HTML Data File"
        "Delivery Group Maintenance Mode,$DGNonMaintenanceCount,$DGMaintenanceCount" | Out-File $HTMLDataFullPath -Append

        # Work Out the Broker Machine Status Details
        Write-Verbose "Querying Broker Machine Details"
        if ($Workload -eq "server") {
            $BrokerMachines = Get-BrokerMachine | Where-Object {$_.SessionSupport -eq "MultiSession"} | Select HostedMachineName, DesktopKind, InMaintenanceMode, PowerState, RegistrationState, SessionSupport, WindowsConnectionSetting, ZoneName
        }
        else {
            $BrokerMachines = Get-BrokerMachine | Where-Object {$_.SessionSupport -eq "SingleSession"} | Select HostedMachineName, DesktopKind, InMaintenanceMode, PowerState, RegistrationState, SessionSupport, WindowsConnectionSetting, ZoneName
        }
        $BMFullCount = ($BrokerMachines | Measure).Count
        $BMMaintenanceCount = ($BrokerMachines | Where-Object {($_.InMaintenanceMode -match "True" -and $_.PowerState -match "On")} | Measure).Count
        $BMOffCount = ($BrokerMachines | Where-Object {($_.PowerState -match "Off")} | Measure).Count
        $BMOnCount = ($BrokerMachines | Where-Object {($_.PowerState -match "On")} | Measure).Count
        $BMRegisteredCount = ($BrokerMachines | Where-Object {($_.RegistrationState -eq "Registered" -and $_.PowerState -match "On")} | Measure).Count
        $BMUnRegisteredCount = ($BrokerMachines | Where-Object {($_.RegistrationState -eq "Unregistered" -and $_.PowerState -match "On")} | Measure).Count

        Write-Verbose "Total Number of Broker Machines: $BMFullCount"
        Write-Verbose "Total Number of Broker Machines in Maintenance Mode: $BMMaintenanceCount"
        Write-Verbose "Total Number of Broker Machines Powered Off: $BMOffCount"
        Write-Verbose "Total Number of Broker Machines Powered On: $BMOnCount"
        Write-Verbose "Total Number of Broker Machines Powered On and Registered: $BMRegisteredCount"
        Write-Verbose "Total Number of Broker Machines Powered On and Un-Registered: $BMUnRegisteredCount"

        # Write Broker Machine Error Data to Error Log File
        $BMUnRegistered = $BrokerMachines | Where-Object {($_.RegistrationState -eq "Unregistered" -and $_.PowerState -match "On")}
        foreach ($Machine in $BMUnRegistered) {
            $Name = $Machine.hostedmachinename
            "$Name is not registered with a XenDesktop Controller" | Out-File $ErroFileFullPath -Append
        }

        # Writing Broker Machine Information to HTML Data File
        Write-Verbose "Writing Broker Machine Details to HTML Data File"
        "Broker Machine Power State,$BMOnCount,$BMOffCount" | Out-File $HTMLDataFullPath -Append
        "Broker Machine Registration,$BMRegisteredCount,$BMUnRegisteredCount" | Out-File $HTMLDataFullPath -Append
        "Broker Machine Maintenance Mode,$BMOnCount,$BMMaintenanceCount" | Out-File $HTMLDataFullPath -Append

        # Setup Variables to track the status of the Broker Machines
        $BrokerGood = 0
        $BrokerBad = 0

        #Build Broker Machines that are up
        $BMUp = $BrokerMachines | Where-Object {($_.PowerState -match "On")} 

        #Loop Through Broker Machines and make sure that all the required checks pass
        foreach ($BM in $BMUp) {
            $Machine = $BM.HostedMachineName

            # Check the server is actually up and running
            if ((Connect-Server $Machine) -eq "Successful") {
                Write-Verbose "$Machine is up"
                # Check the Boot Status for the server
                $Uptime = Get-Uptime $Machine
                If ($Uptime -lt [int]$BootThreshold) {
                    Write-Verbose "$Machine has been booted within the boot threashold of $BootThreshold"
                    # Check the Windows Activation Status for the server
                    If ((Get-ActivationStatus $Machine) -eq "Licensed") {
                        Write-Verbose "$Machine has had Windows Activated"
                        # Check the Load Status for the server
                        $Load = Get-BrokerMachine -HostedMachineName $Machine -Property LoadIndex
                        $CurrentLoad = $Load.LoadIndex
                        If ($CurrentLoad -lt $HighLoad) {
                            Write-Verbose "$Machine has acceptable load - $CurrentLoad"
                            If ($ControlUp -eq "yes") {
                                $CurrentServiceStatus = Check-Service $Machine cuAgent 
                                If ($CurrentServiceStatus -ne "Running") {
                                    $BrokerBad ++
                                    Write-Verbose "Control Up Agent is not running on $Machine"
                                    "Control Up Agent is not running on $Machine" | Out-File $ErroFileFullPath -Append
                                }
                                else {
                                    $BrokerGood ++    
                                    Write-Verbose "Control Up Agent is running on $Machine"                             
                                }
                            }
                            else {
                                $BrokerGood ++
                                Write-Verbose "Control Up Not Enabled - Skipping Check"
                            }
                        }
                        else {
                            $BrokerBad ++
                            Write-Verbose "$Machine has unacceptable load - $CurrentLoad"
                            "$Machine has a high load of $CurrentLoad" | Out-File $ErroFileFullPath -Append
                        }
                    }
                    else {
                        $BrokerBad ++
                        Write-Verbose "$Machine has NOT had Windows Activated"
                        "$Machine is not activated" | Out-File $ErroFileFullPath -Append
                    }
                }
                else {
                    $BrokerBad ++
                    Write-Verbose "$Machine has NOT been booted within the boot threashold of $BootThreshold"
                    "$Machine has not been booted in $Uptime days" | Out-File $ErroFileFullPath -Append
                }
            }
            else {
                $BrokerBad ++
                Write-Verbose "$Machine is down"
                "$Machine is down" | Out-File $ErroFileFullPath -Append
            }
        }

        # Writing Donut File Data
        Write-Verbose "Writing Donut Data File for $Workload"
        Write-Verbose "$Workload Broker Machine Status - Good: $BrokerGood / Bad: $BrokerBad"
        "Broker Machine Status,$BrokerGood,$BrokerBad" | Out-File $DonutFullPath -Append

        # Writing the Donut HTML Output File
        $DonutFile = Join-Path -Path $OutputLocation -ChildPath "$WorkLoad-donut.html"
        Write-Verbose "Donut File Path - $DonutFile"
        Write-Verbose "Building the donut File for $Workload"
        Write-Verbose "Donut File - $DonutFile"
        Write-Verbose "Donut File Path - $DonutFullPath"
        Write-Verbose "Worker Donut Width - $WorkerDonutSize"
        Write-Verbose "Worker Donut Height - $WorkerDonutSize"
        Write-Verbose "Up Colour - $UpColour"
        Write-Verbose "Down Colour - $DownColour"
        Write-Verbose "Donut Stroke - $DonutStroke"

        if ($Workload -eq "server") {
            $ServiceName = "XenDesktop Server WorkLoads"
        }
        else {
            $ServiceName = "XenDesktop Desktop WorkLoads"
        }
      
        Build-Donut $DonutFile $DonutFullPath $WorkerDonutSize $WorkerDonutSize $UpColour $DownColour $WorkerDonutStroke $ServiceName
        
        # Removing Donut Data File
        remove-item $DonutFullPath -Force
        Write-Verbose "Deleted Donut Data File $DonutFullPath"
    }

    # Start Infrastructure Monitoring Checks
    Write-Verbose "Starting Citrix Platform Infrastructure Testing"

    # Checking XenServer
    if ($TestXenServer -eq "yes") {
        # Increment Infrastructure Components
        $InfrastructureComponents++
        $InfrastructureComponents++
        $InfrastructureList += "xenserverpool"
        $InfrastructureList += "xenserverhost"

        Write-Verbose "XenServer Testing enabled"
        Write-Verbose "Building XenServer Data Output Files"
        $XenServerData = Join-Path -Path $OutputLocation -ChildPath "xenserver-data.txt"

        # Build 2 Donut File Paths for XenServer Host and Pools
        $PoolFileName = Join-Path -Path $OutputLocation -ChildPath "xenserverpool.txt"
        $HostFileName = Join-Path -Path $OutputLocation -ChildPath "xenserverhost.txt"
        $PoolFileDonut = Join-Path -Path $OutputLocation -ChildPath "xenserverpool.html"
        $HostFileDonut = Join-Path -Path $OutputLocation -ChildPath "xenserverhost.html"

        # Remove Existing Data Files
        if (test-path $XenServerData) {
            Remove-Item $XenServerData
        }

        # Test the XenServer Infrastructure
        Test-XenServer $PoolMasters $ConnectionPort $InfraErrorFileFullPath $XenServerData $XenUserName $XenPassword

        # Split output file into 2 html data files
        $XenData = Get-Content $XenServerData
        foreach ($Line in $XenData) {
            $LineData = $Line -Split ","
            $FileName = $LineData[0]
            [int]$Good = $LineData[1]
            [int]$Bad = $LineData[2]

            $NewFileName = Join-Path -Path $OutputLocation -ChildPath "$Filename.txt"

            "$FileName,$Good,$Bad" | Out-File $NewFileName
        }

        Write-Verbose "Building Donut Files for XenServers Hosts and Pools"
        Build-Donut $PoolFileDonut $PoolFileName $InfraDonutSize $InfraDonutSize $UpColour $DownColour $InfraDonutStroke "Pools"
        Build-Donut $HostFileDonut $HostFileName $InfraDonutSize $InfraDonutSize $UpColour $DownColour $InfraDonutStroke "Hosts"

        # Removing Donut Data File
        remove-item $PoolFileName -Force
        Write-Verbose "Deleted Donut Data File $PoolFileName"
        remove-item $HostFileName -Force
        Write-Verbose "Deleted Donut Data File $HostFileName"
        remove-item $XenServerData -Force
        Write-Verbose "Deleted Donut Data File $XenServerData"
    }

    # Checking Licensing
    if ($TestLicensing -eq "yes") {
        # Increment Infrastructure Components
        $InfrastructureComponents++
        $InfrastructureList += "licensing"

        Write-Verbose "Citrix Licensing Testing enabled"
        Write-Verbose "Building Citrix Licensing Data Output Files"
        $LicensingData = Join-Path -Path $OutputLocation -ChildPath "license-data.txt"

        # Build Donut File Paths for Licensing
        $LicensingDonut = Join-Path -Path $OutputLocation -ChildPath "licensing.html"

        # Remove Existing Data Files
        if (test-path $LicensingData) {
            Remove-Item $LicensingData
        }

        # Test the Licensing Infrastructure
        Test-Licensing $LicenseServers $VendorDaemonPort $LicensePort $WebAdminPort $SimpleLicensePort $InfraErrorFileFullPath $LicensingData

        Write-Verbose "Building Donut Files for Licensing"
        Build-Donut $LicensingDonut $LicensingData $InfraDonutSize $InfraDonutSize $UpColour $DownColour $InfraDonutStroke "Licensing"

        # Removing Donut Data File
        remove-item $LicensingData -Force
        Write-Verbose "Deleted Donut Data File $LicensingData"
    }
  
    # Checking StoreFront
    if ($TestStoreFront -eq "yes") {
        # Increment Infrastructure Components
        $InfrastructureComponents++
        $InfrastructureList += "storefront"

        Write-Verbose "StoreFront Testing enabled"
        Write-Verbose "Building StoreFront Data Output Files"
        $StoreFrontData = Join-Path -Path $OutputLocation -ChildPath "storefront-data.txt"

        # Build Donut File Paths for StoreFront
        $StoreFrontDonut = Join-Path -Path $OutputLocation -ChildPath "storefront.html"

        # Remove Existing Data Files
        if (test-path $StoreFrontData) {
            Remove-Item $StoreFrontData
        }

        # Test the StoreFront Infrastructure
        Test-StoreFront $StoreFrontServers $StoreFrontPort $StoreFrontPath $StoreFrontProtocol $InfraErrorFileFullPath $StoreFrontData

        Write-Verbose "Building Donut Files for StoreFront"
        Build-Donut $StoreFrontDonut $StoreFrontData $InfraDonutSize $InfraDonutSize $UpColour $DownColour $InfraDonutStroke "StoreFront"

        # Removing Donut Data File
        remove-item $StoreFrontData -Force
        Write-Verbose "Deleted Donut Data File $StoreFrontData"
    }

    # Checking Director
    if ($TestDirector -eq "yes") {
        # Increment Infrastructure Components
        $InfrastructureComponents++
        $InfrastructureList += "director"

        Write-Verbose "Director Testing enabled"
        Write-Verbose "Building Director Data Output Files"
        $DirectorData = Join-Path -Path $OutputLocation -ChildPath "director-data.txt"

        # Build Donut File Paths for Director
        $DirectorDonut = Join-Path -Path $OutputLocation -ChildPath "director.html"

        # Remove Existing Data Files
        if (test-path $DirectorData) {
            Remove-Item $DirectorData
        }

        # Test the Director Infrastructure
        Test-Director $DirectorServers $DirectorPort $DirectorPath $DirectorProtocol $InfraErrorFileFullPath $DirectorData

        Write-Verbose "Building Donut Files for StoreFront"
        Build-Donut $DirectorDonut $DirectorData $InfraDonutSize $InfraDonutSize $UpColour $DownColour $InfraDonutStroke "Director"

        # Removing Donut Data File
        remove-item $DirectorData -Force
        Write-Verbose "Deleted Donut Data File $DirectorData"
    }

    # Checking Controllers
    if ($TestController -eq "yes") {
        # Increment Infrastructure Components
        $InfrastructureComponents++
        $InfrastructureList += "controller"

        Write-Verbose "Controller Testing enabled"
        Write-Verbose "Building Controller Data Output Files"
        $ControllerData = Join-Path -Path $OutputLocation -ChildPath "controller-data.txt"

        # Build Donut File Paths for StoreFront
        $ControllerDonut = Join-Path -Path $OutputLocation -ChildPath "controller.html"

        # Remove Existing Data Files
        if (test-path $ControllerData) {
            Remove-Item $ControllerData
        }

        # Test the StoreFront Infrastructure
        Test-Controllers $ControllerServers $ControllerPort $ControllerServices $InfraErrorFileFullPath $ControllerData

        Write-Verbose "Building Donut Files for Citrix XenDesktop Controllers"
        Build-Donut $ControllerDonut $ControllerData $InfraDonutSize $InfraDonutSize $UpColour $DownColour $InfraDonutStroke "Controllers"

        # Removing Donut Data File
        remove-item $ControllerData -Force
        Write-Verbose "Deleted Donut Data File $ControllerData"
    }

    # Checking Provisioning Servers
    if ($TestProvisioningServer -eq "yes") {
        # Increment Infrastructure Components
        $InfrastructureComponents++
        $InfrastructureList += "ProvisioningServer"

        Write-Verbose "Provisioning Server Testing enabled"
        Write-Verbose "Building Provisioning Server Data Output Files"
        $ProvisioningServerData = Join-Path -Path $OutputLocation -ChildPath "ProvisioningServer-data.txt"

        # Build Donut File Paths for Provisioning Server
        $ProvisioningServerDonut = Join-Path -Path $OutputLocation -ChildPath "ProvisioningServer.html"

        # Remove Existing Data Files
        if (test-path $ProvisioningServerData) {
            Remove-Item $ProvisioningServerData
        }

        # Test the Provisioning Server Infrastructure
        Test-ProvisioningServers $ProvisioningServers $ProvisioningServerPort $ProvisioningServerServices $InfraErrorFileFullPath $ProvisioningServerData

        Write-Verbose "Building Donut Files for Citrix Provisioning Servers"
        Build-Donut $ProvisioningServerDonut $ProvisioningServerData $InfraDonutSize $InfraDonutSize $UpColour $DownColour $InfraDonutStroke "PVS"

        # Removing Donut Data File
        remove-item $ProvisioningServerData -Force
        Write-Verbose "Deleted Donut Data File $ProvisioningServerData"
    }

    # Checking NetScaler
    if ($TestNetScaler -eq "yes") {
        # Increment Infrastructure Components
        $InfrastructureComponents++
        $InfrastructureComponents++
        $InfrastructureList += "netscaler"
        $InfrastructureList += "vserver"

        Write-Verbose "NetScaler Testing enabled"
        Write-Verbose "Building NetScaler Data Output Files"
        $NetScalerData = Join-Path -Path $OutputLocation -ChildPath "netscaler-data.txt"

        # Build 2 Donut File Paths for NetScaler Host and Pools
        $NetScalerFileName = Join-Path -Path $OutputLocation -ChildPath "netscaler.txt"
        $vServerFileName = Join-Path -Path $OutputLocation -ChildPath "vserver.txt"
        $NetScalerFileDonut = Join-Path -Path $OutputLocation -ChildPath "netscaler.html"
        $vServerFileDonut = Join-Path -Path $OutputLocation -ChildPath "vserver.html"

        # Remove Existing Data Files
        if (test-path $NetScalerData) {
            Remove-Item $NetScalerData
        }

        # Test the NetScaler Infrastructure
        Test-NetScaler $NetScalers $NetScalerUserName $NetScalerPassword  $InfraErrorFileFullPath $NetScalerData

        # Split output file into 2 html data files
        $NetData = Get-Content $NetScalerData
        foreach ($Line in $NetData) {
            $LineData = $Line -Split ","
            $FileName = $LineData[0]
            [int]$Good = $LineData[1]
            [int]$Bad = $LineData[2]

            $NewFileName = Join-Path -Path $OutputLocation -ChildPath "$Filename.txt"

            "$FileName,$Good,$Bad" | Out-File $NewFileName
        }

        Write-Verbose "Building Donut Files for NetScalers and vServers"
        Build-Donut $NetScalerFileDonut $NetScalerFileName $InfraDonutSize $InfraDonutSize $UpColour $DownColour $InfraDonutStroke "NetScalers"
        Build-Donut $vServerFileDonut $vServerFileName $InfraDonutSize $InfraDonutSize $UpColour $DownColour $InfraDonutStroke "LoadBalancer"

        # Removing Donut Data File
        remove-item $NetScalerFileName -Force
        Write-Verbose "Deleted Donut Data File $PoolFilNetScalerFileNameeName"
        remove-item $vServerFileName -Force
        Write-Verbose "Deleted Donut Data File $vServerFileName"
        remove-item $NetScalerData -Force
        Write-Verbose "Deleted Donut Data File $NetScalerData"
    }

    # Checking NetScaler Gateway
    if ($TestNetScalerGateway -eq "yes") {
        
        Write-Verbose "NetScaler Gateway Testing enabled"
        Write-Verbose "Building NetScaler Gateway Data Output Files"
        $NetScalerGatewayData = Join-Path -Path $OutputLocation -ChildPath "netscaler-gateway-data.txt"

        # Remove Existing Data Files
        if (test-path $NetScalerGatewayData) {
            Remove-Item $NetScalerGatewayData
        }

        # Test the NetScaler Gateway
        $ICAUsers = (((Get-AAAUsers $NetScalerHostingGateway $NetScalerUserName $NetScalerPassword "ica").vpnicaconnection) | measure).count
        $VPNUsers = (((Get-AAAUsers $NetScalerHostingGateway $NetScalerUserName $NetScalerPassword "vpn").aaasession) | measure).count
        
        "Total ICA Users - $ICAUsers" | Out-File $NetScalerGatewayData -Append
        Write-Verbose "Current NetScaler Gateway ICA Users: $ICAUsers"
        "Total VPN Users - $vpnusers" | Out-File $NetScalerGatewayData -Append
        Write-Verbose "Current NetScaler Gateway VPN Users: $VPNUsers"
        $TotalUsers = [int]$ICAUsers + [int]$VPNUsers
        "Total Users - $TotalUsers" | Out-File $NetScalerGatewayData -Append
        Write-Verbose "Current NetScaler Gateway Users: $TotalUsers"
    }
    
    # Checking WEM Servers
    if ($TestWEM -eq "yes") {
        # Increment Infrastructure Components
        $InfrastructureComponents++
        $InfrastructureList += "WEM"

        Write-Verbose "Citrix WEM Server Testing enabled"
        Write-Verbose "Building Citrix WEM Server Data Output Files"
        $WEMServerData = Join-Path -Path $OutputLocation -ChildPath "WEM-data.txt"

        # Build Donut File Paths for Citrix WEM
        $WEMDonut = Join-Path -Path $OutputLocation -ChildPath "WEM.html"

        # Remove Existing Data Files
        if (test-path $WEMServerData) {
            Remove-Item $PWEMServerData
        }

        # Test the Workspace Environment Management Infrastructure
        Test-WEM $WEMServers $WEMAgentServicePort $WEMServices $InfraErrorFileFullPath $WEMServerData

        Write-Verbose "Building Donut Files for Citrix Workspace Environment Management"
        Build-Donut $WEMDonut $WEMServerData $InfraDonutSize $InfraDonutSize $UpColour $DownColour $InfraDonutStroke "WEM"

        # Removing Donut Data File
        remove-item $WEMServerData -Force
        Write-Verbose "Deleted Donut Data File $WEMServerData"
    }

    # Checking Citrix Universal Print Servers
    if ($TestUPS -eq "yes") {
        # Increment Infrastructure Components
        $InfrastructureComponents++
        $InfrastructureList += "UPS"

        Write-Verbose "Citrix Universal Print Server Testing enabled"
        Write-Verbose "Building Citrix Universal Print Server Data Output Files"
        $UPSServerData = Join-Path -Path $OutputLocation -ChildPath "UPSServer-data.txt"

        # Build Donut File Paths for Citrix Universal Print Server
        $UPSDonut = Join-Path -Path $OutputLocation -ChildPath "UPS.html"

        # Remove Existing Data Files
        if (test-path $UPSServerData) {
            Remove-Item $UPSServerData
        }

        # Test the Universal Print Server Infrastructure
        Test-UPS $UPSServers $UPSPort $UPSServices $InfraErrorFileFullPath $UPSServerData

        Write-Verbose "Building Donut Files for Citrix Univeral Print Servers"
        Build-Donut $UPSDonut $UPSServerData $InfraDonutSize $InfraDonutSize $UpColour $DownColour $InfraDonutStroke "UPS"

        # Removing Donut Data File
        remove-item $UPSServerData -Force
        Write-Verbose "Deleted Donut Data File $UPSServerData"
    }

   # Checking Citrix Federated Authentication Servers
   if ($TestFAS -eq "yes") {
        # Increment Infrastructure Components
        $InfrastructureComponents++
        $InfrastructureList += "FAS"

        Write-Verbose "Federated Authentication Server Testing enabled"
        Write-Verbose "Building Federated Authentication Server Data Output Files"
        $FASServerData = Join-Path -Path $OutputLocation -ChildPath "FASServer-data.txt"

        # Build Donut File Paths for Federated Authentication Server
        $FASDonut = Join-Path -Path $OutputLocation -ChildPath "FAS.html"

        # Remove Existing Data Files
        if (test-path $FASServerData) {
            Remove-Item $FASServerData
        }

        # Test the Federated Authentication Server Infrastructure
        Test-FAS $FASServers $FASPort $FASServices $InfraErrorFileFullPath $FASServerData

        Write-Verbose "Building Donut Files for Citrix Federated Authentication Servers"
        Build-Donut $FASDonut $FASServerData $InfraDonutSize $InfraDonutSize $UpColour $DownColour $InfraDonutStroke "FAS"

        # Removing Donut Data File
        remove-item $FASServerData -Force
        Write-Verbose "Deleted Donut Data File $FASServerData"
    }
  
    # Build the HTML output file
    New-HTMLReport $HTMLOutput $OutputLocation $InfrastructureComponents $InfrastructureList $WorkLoads $RootDirectory

    # Stop the timer and display the output
    $EndTime = (Get-Date)
    Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalSeconds) Seconds" -Verbose
    Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalMinutes) Minutes" -Verbose

    # Stop the transcript
    Stop-Transcript
}
else {
    write-verbose "Path not found to json"
}

# Set the old Verbose Preference back to original value
$VerbosePreference = $OldVerbosePreference

}
