function Test-IP {
    <# 
    .SYNOPSIS 
        Validate a passed in IP Address.
    .DESCRIPTION 
        Validate a passed in IP Address.
    .PARAMETER IPAddress 
        IP Address to be validated. 
    .NOTES 
        Name: Test-IP
        Author: David Brett
        Date Created: 15/03/2017 
    .CHANGE LOG
        David Brett - 15/03/2017 - Initial Script Creation 
#> 

    [cmdletbinding(
        DefaultParameterSetName = '',
        ConfirmImpact = 'low'
    )]
    [OutputType([System.boolean])]

    Param (
        [Parameter(
            Mandatory = $False,
            Position = 0,
            ParameterSetName = '',
            ValueFromPipeline = $True)]
        [string]$IPAddress
    )

    if ([BOOL]($IPAddress -as [IPADDRESS])) {
        Write-Verbose "$IPAddress is valid"
        return $True 
    }
    else {
        Write-Verbose "$IPAddress is an invalid address - quitting"
        break
    }
}
