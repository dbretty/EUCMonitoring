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
    # Test the NetScaler Gateway

    # XXX CHANGEME XXX  - Error Checking?  
    $ICAUsers = (((Get-AAAUser $NetScalerHostingGateway $NetScalerUserName $NetScalerPassword "ica").vpnicaconnection) | Measure-Object).count
    $VPNUsers = (((Get-AAAUser $NetScalerHostingGateway $NetScalerUserName $NetScalerPassword "vpn").aaasession) | Measure-Object).count


    Write-Verbose "Current NetScaler Gateway ICA Users: $ICAUsers"
    Write-Verbose "Current NetScaler Gateway VPN Users: $VPNUsers"
    $TotalUsers = [int]$ICAUsers + [int]$VPNUsers
    Write-Verbose "Current NetScaler Gateway Users: $TotalUsers"

    $gwresults += [PSCustomObject]@{
    #    'NetScalerGateway' = $NetScalerHostingGateway
        'ICAUsers'         = $ICAUsers
        'VPNUsers'         = $VPNUsers
    }
    return $gwresults
}
