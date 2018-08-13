Function Test-XdSessionInfo {
    <#   
.SYNOPSIS   
    Returns Stats of the XenDesktop Sessions
.DESCRIPTION 
    Returns Stats of the XenDesktop Sessions
.PARAMETER Broker 
    XenDesktop Broker to use for the checks

.NOTES
    Current Version:        1.0
    Creation Date:          29/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             29/03/2018          Function Creation
    Adam Yarborough         1.1             07/06/2018          Update to new object model
    Adam Yarborough         1.2             20/06/2018          Session Information
.EXAMPLE
    None Required
#>
    Param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Broker
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

        $ctxsnap = Add-PSSnapin Citrix.Configuration.Admin.* -ErrorAction SilentlyContinue
        $ctxsnap = Get-PSSnapin Citrix.Configuration.Admin.* -ErrorAction SilentlyContinue

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
        $Results = @()
        $Errors = @()
        
        $SiteName = (Get-BrokerSite -AdminAddress $Broker).Name
        $ZoneNames = (Get-ConfigZone -AdminAddress $Broker).Name
        
        Foreach ($ZoneName in $ZoneNames) {

            Get-BrokerDesktopGroup -AdminAddress $Broker | ForEach-Object {
                Write-Verbose "Getting session details "
                $DeliveryGroupName = $_.Name
                $TotalSessions = $_.Sessions
                Write-Verbose "Getting session details for Delivery Group: $DeliveryGroupName"

                $params = @{
                    AdminAddress     = $Broker;
                    DesktopGroupName = $DeliveryGroupName;
                    SessionState     = "Active";
                    Maxrecordcount   = 99999
                }
                $Sessions = Get-BrokerSession @params
                $ActiveSessions = ($Sessions | Where-Object IdleDuration -lt 00:00:01).Count
                $IdleSessions = ($Sessions | Where-Object IdleDuration -gt 00:00:00).Count
                
                
                $BrokerDurationMin = ($Sessions.BrokeringDuration | Measure-Object -Minimum).Minimum
                $BrokerDurationAvg = ($Sessions.BrokeringDuration | Measure-Object -Average).Average
                $BrokerDurationMax = ($Sessions.BrokeringDuration | Measure-Object -Maximum).Maximum
                # In case of no Broker info returned
                if ($null -eq $BrokerDurationMin) {
                    $BrokerDurationMin = 0
                    $BrokerDurationAvg = 0 
                    $BrokerDurationMax = 0 
                }
                
                # If one is null, all are null. 
            
                $params = @{
                    AdminAddress     = $Broker;
                    DesktopGroupName = $DeliveryGroupName;
                    ZoneName         = $ZoneName;
                    Maxrecordcount   = 99999
                }
                $Machines = Get-BrokerMachine @params
            
                $LoadIndexMin = ($Machines.LoadIndex | Measure-Object -Minimum).Minimum
                $LoadIndexAvg = ($Machines.LoadIndex | Measure-Object -Average).Average
                $LoadIndexMax = ($Machines.LoadIndex | Measure-Object -Maximum).Maximum
                # In case load index not returned. 
                if ($null -eq $LoadIndexMin) {
                    $LoadIndexMin = 0
                    $LoadIndexAvg = 0
                    $LoadIndexMax = 0
                }
                $params = @{
                    AdminAddress     = $Broker;
                    DesktopGroupName = $DeliveryGroupName;
                    SessionState     = "Disconnected";
                    Maxrecordcount   = 99999
                }
                $DisconnectedSessions = (Get-BrokerSession @params).Count

                Write-Verbose "SiteName             = $SiteName"
                Write-Verbose "DeliveryGroupName    = $DeliveryGroupName"
                Write-Verbose "TotalSessions        = $TotalSessions"
                Write-Verbose "ActiveSessions       = $ActiveSessions"
                Write-Verbose "IdleSessions         = $IdleSessions"

                Write-Verbose "DisconnectedSessions = $DisconnectedSessions"

                $Results += [PSCustomObject]@{
                    'SiteName'             = $SiteName   
                    'ZoneName'             = $ZoneName
                    'DeliveryGroupName'    = $DeliveryGroupName
                    'TotalSessions'        = $TotalSessions
                    'ActiveSessions'       = $ActiveSessions
                    'IdleSessions'         = $IdleSessions
                    'DisconnectedSessions' = $DisconnectedSessions
                    'BrokerDurationMin'    = $BrokerDurationMin
                    'BrokerDurationAvg'    = $BrokerDurationAvg
                    'BrokerDurationMax'    = $BrokerDurationMax
                    'LoadIndexMin'         = $LoadIndexMin
                    'LoadIndexAvg'         = $LoadIndexAvg
                    'LoadIndexMax'         = $LoadIndexMax
                    'Errors'               = $Errors
                }
            }
        }
        return $Results
    }

    End { }
}