function Test-XdWorker {
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
.NOTES
    Current Version:        1.0
    Creation Date:          29/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             29/03/2018          Function Creation
    Adam Yarborough         1.1             07/06/2018          Update to new object model
    Adam Yarborough         1.2             20/06/2018          Updated Objects, begin/process/end
    Adam Yarborough         1.3             23/07/2018          Change Advanced to include BrokerGood/BrokerBad
                                                                renamed iterator to details to avoid name clash
                                                                with system variable $error
.EXAMPLE
    None Required
#>

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Broker,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$WorkerTestMode,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$WorkLoad,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$BootThreshold,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$HighLoad

    )

    Begin {
        $ctxsnap = Add-PSSnapin Citrix.Broker.* -ErrorAction SilentlyContinue
        $ctxsnap = Get-PSSnapin Citrix.Broker.* -ErrorAction SilentlyContinue

        if ($null -eq $ctxsnap) {
            Write-Error "XenDesktop Powershell Snapin Load Failed"
            Write-Error "Cannot Load XenDesktop Powershell SDK"
            Return
        }
        else {
            Write-Verbose "XenDesktop Powershell SDK Snapin Loaded"
        }
    }

    Process {
        #Create array with results
        $results = @()
        $errors = @()
        # Initialize Arrays and Variables
        Write-Verbose "Variables and Arrays Initalized"

        # Get Delivery Groups and Maintenance Mode Details
        Write-Verbose "Querying Delivery Group Maintenance Mode Details"

        # Get Full List Of Delivery Groups
        Write-Verbose "Getting Delivery Groups for Type - $WorkLoad"
        if ($Workload -eq "server") {
            $DeliveryGroups = Get-BrokerDesktopGroup -AdminAddress $Broker | Where-Object {$_.SessionSupport -eq "MultiSession"} | Select-Object PublishedName, InMaintenanceMode
            $TotalConnectedUsers = (((get-brokersession -MaxRecordCount 5000) | where-object {$_.DesktopKind -eq "Shared" -and $_.SessionState -eq "Active"}) | Measure-Object).Count
            $TotalUsersDisconnected = (((get-brokersession -MaxRecordCount 5000) | where-object {$_.DesktopKind -eq "Shared" -and $_.SessionState -ne "Active"}) | Measure-Object).Count
        }
        else {
            $DeliveryGroups = Get-BrokerDesktopGroup -AdminAddress $Broker | Where-Object {$_.SessionSupport -eq "SingleSession"} | Select-object PublishedName, InMaintenanceMode
            $TotalConnectedUsers = (((get-brokersession -AdminAddress $Broker -MaxRecordCount 5000) | where-object {$_.DesktopKind -ne "Shared" -and $_.SessionState -eq "Active"}) | Measure-Object).Count
            $TotalUsersDisconnected = (((get-brokersession -AdminAddress $Broker -MaxRecordCount 5000) | where-object {$_.DesktopKind -ne "Shared" -and $_.SessionState -ne "Active"}) | Measure-Object).Count
        }

        $SiteName = (Get-BrokerSite -AdminAddress $Broker).Name

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
            $BrokerMachines = Get-BrokerMachine -AdminAddress $Broker | Where-Object {$_.SessionSupport -eq "MultiSession"} | Select-Object HostedMachineName, DesktopKind, InMaintenanceMode, PowerState, RegistrationState, SessionSupport, WindowsConnectionSetting, ZoneName
        }
        else {
            $BrokerMachines = Get-BrokerMachine -AdminAddress $Broker | Where-Object {$_.SessionSupport -eq "SingleSession"} | Select-Object HostedMachineName, DesktopKind, InMaintenanceMode, PowerState, RegistrationState, SessionSupport, WindowsConnectionSetting, ZoneName
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
            $errors += "$Name is not registered with a XenDesktop Controller"
        }

        if ($WorkerTestMode -eq "basic") {
            # Add results to array
            $results += [PSCustomObject]@{
                'SiteName'                       = $SiteName
                'WorkLoad'                       = $WorkLoad
                'ConnectedUsers'                 = $TotalConnectedUsers
                'DisconnectedUsers'              = $TotalUsersDisconnected
                'DeliveryGroupsNotInMaintenance' = $DGNonMaintenanceCount
                'DeliveryGroupsInMaintenance'    = $DGMaintenanceCount
                'BrokerMachineOn'                = $BMOnCount
                'BrokerMachineOff'               = $BMOffCount
                'BrokerMachineRegistered'        = $BMRegisteredCount
                'BrokerMachineUnRegistered'      = $BMUnRegisteredCount
                'BrokerMachineInMaintenance'     = $BMMaintenanceCount
                'Errors'                         = $Errors
            }

            #returns object with test results
            return $results

        }
        else {
            Write-Verbose "Advanced Worker Checks enabled - setting up runspace and checking workers"
            $BrokerGood = 0
            $BrokerBad = 0
            $BMRegisteredList = $BrokerMachines | Where-Object {($_.RegistrationState -eq "Registered" -and $_.PowerState -match "On")}
            $DetailErrors = Test-XdWorkerAdvanced -Broker $Broker -Machines $BMRegisteredList -BootThreshold $BootThreshold -HighLoad $HighLoad

            foreach ($detail in $DetailErrors) {
                if ($null -ne $detail.services) {
                    if ($detail.services -eq "Passed") {
                        $BrokerGood++
                    }
                    else {
                        $BrokerBad++
                        $errors += $detail.errors
                    }
                }
            }

            # Add results to array
            $results += [PSCustomObject]@{
                'SiteName'                       = $SiteName
                'WorkLoad'                       = $WorkLoad
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
                'BrokerMachinesBad'              = $BrokerBad
                'Errors'                         = $Errors
            }

            #returns object with test results
            return $results
        }
    }

    End { }
}
