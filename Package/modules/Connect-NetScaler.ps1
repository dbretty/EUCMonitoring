function Connect-NetScaler {
    <# 
    .SYNOPSIS 
        Logs into a Citrix NetScaler.
    .DESCRIPTION 
        Logs into a NetScaler ADC and creates a global variable called $NSSession to be used to invoke NITRO Commands.
    .PARAMETER NSIP 
        Citrix NetScaler NSIP.
    .PARAMETER UserName 
        UserName to be used for login.
    .PARAMETER Password
        The Password to be used for Login 
    .NOTES 
        Name: Connect-NetScaler
        Author: David Brett
        Date Created: 15/03/2017
    .CHANGE LOG
        David Brett - 15/03/2017 - Initial Script Creation 
#> 

    [cmdletbinding(
        DefaultParameterSetName = '',
        ConfirmImpact = 'low'
    )]

    Param (
        [Parameter(
            Mandatory = $False,
            Position = 0,
            ParameterSetName = '',
            ValueFromPipeline = $True)]
        [string]$NSIP,
        [Parameter(
            Mandatory = $False,
            Position = 1,
            ParameterSetName = '',
            ValueFromPipeline = $True)]
        [string]$UserName,
        [Parameter(
            Mandatory = $False,
            Position = 2,
            ParameterSetName = '',
            ValueFromPipeline = $True)]
        [string]$Password
    )

    # Check to see if parameters were passed in, if not then prompt the user for them
    if ($NSIP -eq "") {$NSIP = read-host "Enter NetScaler IP"}
    if ($UserName -eq "") {$UserName = read-host "Enter NetScaler User Name"}
    if ($Password -eq "") {
        $SecurePassword = read-host "Enter NetScaler Password" -AsSecureString
        $BasePassword = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BasePassword)
    }

    # Validate That the IP Address is valid
    Validate-IP $NSIP

    # Set up the JSON Payload to send to the netscaler    
    $PayLoad = ConvertTo-JSON @{
        "login" = @{
            "username" = $UserName;
            "password" = $Password
        }
    }

    # Connect to NetScaler
    Invoke-RestMethod -uri "$NSIP/nitro/v1/config/login" -body $PayLoad -SessionVariable saveSession -Headers @{"Content-Type" = "application/vnd.com.citrix.netscaler.login+json"} -Method POST

    # Build Global NetScaler Session Variable
    $Global:nsSession = New-Object -TypeName PSObject
    $nsSession | Add-Member -NotePropertyName Endpoint -NotePropertyValue $NSIP -TypeName String
    $nsSession | Add-Member -NotePropertyName WebSession -NotePropertyValue $saveSession -TypeName Microsoft.PowerShell.Commands.WebRequestSession

    # Return NetScaler Session
    return $nsSession
}
