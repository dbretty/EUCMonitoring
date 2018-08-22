function Connect-NetScaler {
    <# 
    .SYNOPSIS 
        Logs into a Citrix NetScaler.
    .DESCRIPTION 
        Logs into a NetScaler ADC and returns variable called $NSSession to be used to invoke NITRO Commands.
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
        Ryan Butler - 27/03/2017 - Change to nssession scope 
        David Brett - 14/06/2018 - Edited the Function to remove positional parameters and cleaned up old code
        Adam Yarborough - 26/07/2018 - Edited to 
#> 

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$NSIP,
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$UserName,
        [parameter(Mandatory = $false, ValueFromPipeline = $true)][System.Security.SecureString]$NSPassword
    )

    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

    # Strip the Secure Password back to a basic text password
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NSPassword)
    $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    # Validate That the IP Address is valid
    # Test-IP $NSIP

    # Set up the JSON Payload to send to the netscaler    
    $PayLoad = ConvertTo-JSON @{
        "login" = @{
            "username" = $UserName;
            "password" = $UnsecurePassword
        }
    }

    # Connect to NetScaler
    Write-Verbose "Connecting to NetScaler using NITRO"
    try {
        Invoke-RestMethod -uri "$NSIP/nitro/v1/config/login" -body $PayLoad -SessionVariable saveSession -Headers @{"Content-Type" = "application/vnd.com.citrix.netscaler.login+json"} -Method POST -ErrorAction Stop
    } 
    catch {
        Write-Warning "Unable to connect to Netscaler $NSIP"
        return $false
    }

    # Build Script NetScaler Session Variable
    $nsSession = New-Object -TypeName PSObject
    $nsSession | Add-Member -NotePropertyName Endpoint -NotePropertyValue $NSIP -TypeName String
    $nsSession | Add-Member -NotePropertyName WebSession -NotePropertyValue $saveSession -TypeName Microsoft.PowerShell.Commands.WebRequestSession

    # Return NetScaler Session
    return $nsSession
}
