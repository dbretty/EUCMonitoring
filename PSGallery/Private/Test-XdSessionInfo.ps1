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
    }

    Process { 
        $Results = @()
        $Errors = @()
        
        $SiteName = (Get-BrokerSite -AdminAddress $Broker).Name

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
                'DeliveryGroupName'    = $DeliveryGroupName
                'TotalSessions'        = $TotalSessions
                'ActiveSessions'       = $ActiveSessions
                'IdleSessions'         = $IdleSessions
                'DisconnectedSessions' = $DisconnectedSessions
                'Errors'               = $Errors
            }
        }

        return $Results
    }

    End { }
}