function Test-NetScalerGateway {
    <#
    
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