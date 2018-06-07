Function Test-XdDesktop {
    <#   
.SYNOPSIS   
    Checks the Status of the XenDesktop Workers Passed In
.DESCRIPTION 
    Checks the Status of the XenDesktop Workers Passed In
.PARAMETER Broker
    XenDesktop Broker to use for the checks
.PARAMETER BootThreshold 
    Desktop Boot Threshold
.PARAMETER HighLoad 
    Desktop High Load
.NOTES
    Current Version:        1.0
    Creation Date:          29/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             29/03/2018          Function Creation
    Adam Yarborough         1.1             07/06/2018          Function Modification

.EXAMPLE
    None Required
#>

    [CmdletBinding()]
    Param (
        $Broker,
        $BootThreshhold,
        $HighLoad
    )
   
    $results = @()
    Write-Verbose "Starting Citrix Platform Worker Testing"
    Write-Verbose "Broker: $Broker"
    Write-Verbose "BootThreshold: $BootThreshold"
    Write-Verbose "HighLoad: $Highload"

    
    # Load the Citrix Broker Powershell SDK
    $ctxsnap = add-pssnapin citrix* -ErrorAction SilentlyContinue
    $ctxsnap = get-pssnapin citrix* -ErrorAction SilentlyContinue

    if ($null -eq $ctxsnap) {
        Write-error "XenDesktop Powershell Snapin Load Failed - No XenDesktop Brokering SDK Found"
        Write-error "Cannot Load XenDesktop Powershell SDK"
        Return # Fix Termination of Powershell instance https://git.io/vxEGW
    }
    else {
        Write-Verbose "XenDesktop Powershell SDK Snapin Loaded"
    }
    
    $DeliveryGroups = Get-BrokerDesktopGroup -AdminAddress $Broker | Where-Object {$_.SessionSupport -eq "SingleSession"} | Select-object PublishedName, InMaintenanceMode
    $ConnectedUsers = (((get-brokersession -AdminAddress $Broker -MaxRecordCount 5000) | where-object {$_.DesktopKind -ne "Shared" -and $_.SessionState -eq "Active"}) | Measure-Object).Count
    $DisconnectedUsers = (((get-brokersession -AdminAddress $Broker -MaxRecordCount 5000) | where-object {$_.DesktopKind -ne "Shared" -and $_.SessionState -ne "Active"}) | Measure-Object).Count
    $DGMaintenanceCount = ($DeliveryGroups | Where-Object {$_.InMaintenanceMode -match "True"} | Measure-Object).Count
    $DGNonMaintenanceCount = ($DeliveryGroups | Where-Object {$_.InMaintenanceMode -match "False"} | Measure-Object).Count


    $BrokerMachines = Get-BrokerMachine | `
        Where-Object {$_.SessionSupport -eq "SingleSession"} | `
        Select-Object HostedMachineName, DesktopKind, InMaintenanceMode, PowerState, RegistrationState, SessionSupport, WindowsConnectionSetting, ZoneName

    
    $BMOffCount = ($BrokerMachines | Where-Object {($_.PowerState -match "Off")} | Measure-Object).Count
    $BMOnCount = ($BrokerMachines | Where-Object {($_.PowerState -match "On")} | Measure-Object).Count
    $BMRegisteredCount = ($BrokerMachines | Where-Object {($_.RegistrationState -eq "Registered" -and $_.PowerState -match "On")} | Measure-Object).Count
    $BMUnRegisteredCount = ($BrokerMachines | Where-Object {($_.RegistrationState -eq "Unregistered" -and $_.PowerState -match "On")} | Measure-Object).Count
    $BMMaintenanceCount = ($BrokerMachines | Where-Object {($_.InMaintenanceMode -match "True" -and $_.PowerState -match "On")} | Measure-Object).Count

    # Circle back around and do this.  
    $BrokerGood = 0
    $BrokerBad = 0

    $results += [PSCustomObject]@{
        'ConnectedUsers'                 = $ConnectedUsers
        'DisconnectedUsers'              = $DisconnectedUsers
        'DeliveryGroupsNotInMaintenance' = $DGNonMaintenanceCount
        'DeliveryGroupsInMaintenance'    = $DGMaintenanceCount
        'BrokerMachinesOn'               = $BMOnCount
        'BrokerMachinesOff'              = $BMOffCount
        'BrokerMachinesRegistered'       = $BMRegisteredCount
        'BrokerMachinesUnRegistered'     = $BMUnRegisteredCount
        'BrokerMachinesInMaintenance'    = $BMMaintenanceCount
        'BrokerMachinesGood'             = $BrokerGood
        'BrokerMachinesBad'              = $BrokerBad
    }

    return $results
}