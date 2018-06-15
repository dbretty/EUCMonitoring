function Disconnect-NetScaler {
    <# 
.SYNOPSIS 
    Logs out of a Citrix NetScaler.
.DESCRIPTION 
    Logs out of a Citrix NetScaler and clears the NSSession Global Variable.
.PARAMETER NSIP 
    Citrix NetScaler NSIP. 
.NOTES 
    Name: Disconnect-NetScaler
    Author: David Brett
    Date Created: 15/03/2017 
.CHANGE LOG
    David Brett     1.0     15/03/2017          Initial Script Creation 
    David Brett     1.1     14/06/2018          Edited the Function to remove positional parameters and cleaned out old code        
#> 

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$NSIP
    )

    # Validate That the IP Address is valid
    Test-IP $NSIP

    # Check to see if a valid NSSession is active. If not then quit the function
    if ($NSSession -eq "") {
        Write-Verbose "No valid NetScaler session found, quitting"
        break
    }

    # Set up the JSON Payload to send to the netscaler
    $PayLoad = ConvertTo-JSON @{
        "logout" = @{
        }
    }

    # Logout of the NetScaler
    Invoke-RestMethod -uri "$NSIP/nitro/v1/config/logout" -body $PayLoad -WebSession $NSSession.WebSession -Headers @{"Content-Type" = "application/vnd.com.citrix.netscaler.logout+json"} -Method POST

}
