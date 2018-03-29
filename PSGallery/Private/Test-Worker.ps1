function Test-Worker {
    <#   
.SYNOPSIS   
    Checks the Status of the XenDesktop Workers Passed In
.DESCRIPTION 
    Checks the Status of the XenDesktop Workers Passed In
.PARAMETER Broker 
    XenDesktop Broker to use for the checks
.PARAMETER WorkerTestMode 
    Test Mode - Basic or Advanced
.PARAMETER WorkLoads 
    Workloads to check
.PARAMETER ServerBootThreshold 
    Server Boot Threshold
.PARAMETER ServerHighLoad 
    Server High Load
.PARAMETER DesktopBootThreshold 
    Desktop Boot Threshold
.PARAMETER DesktopHighLoad 
    Desktop High Load
.PARAMETER ErrorFile 
    Infrastructure Error File to Log To
.NOTES
    Current Version:        1.0
    Creation Date:          29/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             29/03/2018          Function Creation

.EXAMPLE
    None Required
#>

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Broker,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$WorkerTestMode,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$WorkLoad,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ServerBootThreshold,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ServerHighLoad,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DesktopBootThreshold,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DesktopHighLoad,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile
    )

    #Create array with results
    $results = @()

    # Initialize Arrays and Variables
    Write-Verbose "Variables and Arrays Initalized"

    # Get Delivery Groups and Maintenance Mode Details
    Write-Verbose "Querying Delivery Group Maintenance Mode Details"

    # Get Full List Of Delivery Groups
    Write-Verbose "Getting Delivery Groups for Type - $WorkLoad"
    if ($Workload -eq "server") {
        $BootThreshold = $ServerBootThreshold
        $HighLoad = $ServerHighLoad
        $DeliveryGroups = Get-BrokerDesktopGroup -AdminAddress $Broker | Where-Object {$_.SessionSupport -eq "MultiSession"} | Select-Object PublishedName, InMaintenanceMode
        $TotalConnectedUsers = (((get-brokersession -MaxRecordCount 5000) | where-object {$_.DesktopKind -eq "Shared" -and $_.SessionState -eq "Active"}) | Measure-Object).Count
        $TotalUsersDisconnected = (((get-brokersession -MaxRecordCount 5000) | where-object {$_.DesktopKind -eq "Shared" -and $_.SessionState -ne "Active"}) | Measure-Object).Count
    }
    else {
        $BootThreshold = $DesktopBootThreshold
        $HighLoad = $DesktopHighLoad
        $DeliveryGroups = Get-BrokerDesktopGroup -AdminAddress $Broker | Where-Object {$_.SessionSupport -eq "SingleSession"} | Select-object PublishedName, InMaintenanceMode
        $TotalConnectedUsers = (((get-brokersession -MaxRecordCount 5000) | where-object {$_.DesktopKind -ne "Shared" -and $_.SessionState -eq "Active"}) | Measure-Object).Count
        $TotalUsersDisconnected = (((get-brokersession -MaxRecordCount 5000) | where-object {$_.DesktopKind -ne "Shared" -and $_.SessionState -ne "Active"}) | Measure-Object).Count
    }

    # Work out the number of Delivery Groups in Maintenance Mode and write them back to the HTML Data File
    $DGFullCount = ($DeliveryGroups | Measure-Object).Count
    $DGMaintenanceCount = ($DeliveryGroups | Where-Object {$_.InMaintenanceMode -match "True"} | Measure-Object).Count
    $DGNonMaintenanceCount = ($DeliveryGroups | Where-Object {$_.InMaintenanceMode -match "False"} | Measure-Object).Count
    Write-Verbose "Total Number of Delivery Groups: $DGFullCount"
    Write-Verbose "Total Number of Delivery Groups in Maintenance Mode: $DGMaintenanceCount"
    Write-Verbose "Total Number of Delivery Groups in Available Status: $DGNonMaintenanceCount"
    Write-Verbose "Writing Delivery Group Maintenance Mode Details to HTML Data File"

    # Work Out the Broker Machine Status Details
    Write-Verbose "Querying Broker Machine Details"
    if ($Workload -eq "server") {
        $BrokerMachines = Get-BrokerMachine | Where-Object {$_.SessionSupport -eq "MultiSession"} | Select-Object HostedMachineName, DesktopKind, InMaintenanceMode, PowerState, RegistrationState, SessionSupport, WindowsConnectionSetting, ZoneName
    }
    else {
        $BrokerMachines = Get-BrokerMachine | Where-Object {$_.SessionSupport -eq "SingleSession"} | Select-Object HostedMachineName, DesktopKind, InMaintenanceMode, PowerState, RegistrationState, SessionSupport, WindowsConnectionSetting, ZoneName
    }
    $BMFullCount = ($BrokerMachines | Measure-object).Count
    $BMMaintenanceCount = ($BrokerMachines | Where-Object {($_.InMaintenanceMode -match "True" -and $_.PowerState -match "On")} | Measure-Object).Count
    $BMOffCount = ($BrokerMachines | Where-Object {($_.PowerState -match "Off")} | Measure-Object).Count
    $BMOnCount = ($BrokerMachines | Where-Object {($_.PowerState -match "On")} | Measure-Object).Count
    $BMRegisteredCount = ($BrokerMachines | Where-Object {($_.RegistrationState -eq "Registered" -and $_.PowerState -match "On")} | Measure-Object).Count
    $BMUnRegisteredCount = ($BrokerMachines | Where-Object {($_.RegistrationState -eq "Unregistered" -and $_.PowerState -match "On")} | Measure-Object).Count

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
        "$Name is not registered with a XenDesktop Controller" | Out-File $ErrorFile -Append
    }

    if ($WorkerTestMode -eq "basic") {
        # Add results to array
        $results += [PSCustomObject]@{
            'TotalConnectedUsers'            = $TotalConnectedUsers
            'TotalUsersDisconnected'         = $TotalUsersDisconnected
            'DeliveryGroupsNotInMaintenance' = $DGNonMaintenanceCount
            'DeliveryGroupsInMaintenance'    = $DGMaintenanceCount
            'BrokerMachineOn'                = $BMOnCount
            'BrokerMachineOff'               = $BMOffCount
            'BrokerMachineRegistered'        = $BMRegisteredCount
            'BrokerMachineUnRegistered'      = $BMUnRegisteredCount
            'BrokerMachineInMaintenance'     = $BMMaintenanceCount
        }

        #returns object with test results
        return $results

    } else {


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
                                $CurrentServiceStatus = Test-Service $Machine cuAgent 
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
                            "$Machine has a high load of $CurrentLoad" | Out-File $ErrorFile -Append
                        }
                    }
                    else {
                        $BrokerBad ++
                        Write-Verbose "$Machine has NOT had Windows Activated"
                        "$Machine is not activated" | Out-File $ErrorFile -Append
                    }
                }
                else {
                    $BrokerBad ++
                    Write-Verbose "$Machine has NOT been booted within the boot threashold of $BootThreshold"
                    "$Machine has not been booted in $Uptime days" | Out-File $ErrorFile -Append
                }
            }
            else {
                $BrokerBad ++
                Write-Verbose "$Machine is down"
                "$Machine is down" | Out-File $ErrorFile -Append
            }
        }

        # Add results to array
        $results += [PSCustomObject]@{
            'TotalConnectedUsers'            = $TotalConnectedUsers
            'TotalUsersDisconnected'         = $TotalUsersDisconnected
            'DeliveryGroupsNotInMaintenance' = $DGNonMaintenanceCount
            'DeliveryGroupsInMaintenance'    = $DGMaintenanceCount
            'BrokerMachineOn'                = $BMOnCount
            'BrokerMachineOff'               = $BMOffCount
            'BrokerMachineRegistered'        = $BMRegisteredCount
            'BrokerMachineUnRegistered'      = $BMUnRegisteredCount
            'BrokerMachineInMaintenance'     = $BMMaintenanceCount
            'BrokerMachinesGood'             = $BrokerGood
            'BrokerMachinesBad'             = $BrokerBad
        }

        #returns object with test results
        return $results
    }
}
