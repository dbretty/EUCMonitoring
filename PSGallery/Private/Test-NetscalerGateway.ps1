function Test-NetscalerGateway {
    <#
.SYNOPSIS
    Tests Netscaler Gateway
.DESCRIPTION
    Tests Netscaler Gateway
        Grabs AAA users
.PARAMETER NetScalerHostingGateway
    Netscaler hosting gateway
.PARAMETER NetScalerUserName
    Netscaler Username
.PARAMETER NetscalerPassword
    Netscaler Password
.NOTES
    Name                    Version         Date                Change Detail
    Ryan Butler             1.1             29/03/2018          Converted to function
    Adam Yarborough         1.2             05/06/2018          Converted to object
    Adam Yarborough         1.3             23/07/2018          Added connection successful test based on
                                                                returned values of Get-AAAUser.
.EXAMPLE
    None Required
#>
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$NetScalerHostingGateway,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$NetScalerUserName,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][System.Security.SecureString]$NetscalerPassword

    )
    #Create array with results
    $gwresults = @()
    $errors = @()


    # Test the NetScaler Gateway
    $ICAUsers = (((Get-AAAUser $NetScalerHostingGateway $NetScalerUserName $NetScalerPassword "ica").vpnicaconnection) | Measure-Object).count
    $VPNUsers = (((Get-AAAUser $NetScalerHostingGateway $NetScalerUserName $NetScalerPassword "vpn").aaasession) | Measure-Object).count

    # Both of these indicate a problem with the Netscaler Hosting Gateway.
    if (-1 -eq $ICAUsers) {
        Write-Verbose "Could not retrieve ICA Users from Netscaler Gateway $NetscalerHostingGateway"
        $Errors += "Could not retrieve ICA Users from Netscaler Gateway $NetscalerHostingGateway"
    }
    if (-1 -eq $VPNUsers) {
        Write-Verbose "Could not retrieve VPN Users from Netscaler Gateway $NetscalerHostingGateway"
        $Errors += "Could not retrieve VPN Users from Netscaler Gateway $NetscalerHostingGateway"
    }

    if ($Errors.Count -gt 0) {
        $gwresults += [PSCustomObject]@{
            'ICAUsers'          = $ICAUsers
            'VPNUsers'          = $VPNUsers
            'TotalGatewayUsers' = -1 # Manual Override
            'Errors'            = $Errors
        }
    }
    else {
        Write-Verbose "Current NetScaler Gateway ICA Users: $ICAUsers"
        Write-Verbose "Current NetScaler Gateway VPN Users: $VPNUsers"
        $TotalUsers = [int]$ICAUsers + [int]$VPNUsers
        Write-Verbose "Current NetScaler Gateway Users: $TotalUsers"

        $gwresults += [PSCustomObject]@{
            'ICAUsers'          = $ICAUsers
            'VPNUsers'          = $VPNUsers
            'TotalGatewayUsers' = $TotalUsers
        }
    }
    return $gwresults
}
