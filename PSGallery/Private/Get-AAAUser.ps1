function Get-AAAUser {
    <#   
.SYNOPSIS   
    Build a Global Variable with all current vServer Status.
.DESCRIPTION 
    Build a Global Variable with all current vServer Status.
.PARAMETER NSIP 
    NetScaler IP to Connect To 
.PARAMETER UserName 
    NetScaler UserName 
.PARAMETER Password 
    NetScaler Password 
.PARAMETER UserType 
    NetScaler Password
.NOTES
    Current Version:        1.0
    Creation Date:          14/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             14/03/2018          Function Creation
    David Brett             1.2             29/03/2018          Edit NSSession Scope
    David Brett             1.3             15/06/2018          Added Error Checking for the Call to get the Users From the NetScaler
.EXAMPLE
    None Required
#> 

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$NSIP,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$UserName,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][System.Security.SecureString]$Password,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$UserType
    )
    
    $nsSession = Connect-NetScaler $NSIP $UserName $Password

    if ($nsSession -eq $false) {
        Write-Warning "Unable to connect to netscaler.  Check config"
    }
    else {
        if ($UserType -eq "ica") {
            $Url = "$NSIP/nitro/v1/config/vpnicaconnection"
        }
        else {
            $Url = "$NSIP/nitro/v1/config/aaasession"
        }
    
        $Method = "GET"
        $ContentType = "application/json"
        $UserSessions = Invoke-RestMethod -uri $Url -WebSession $nsSession.WebSession -ContentType $ContentType -Method $Method
        
        Disconnect-NetScaler -NSIP $NSIP -nssession $nsSession
    
        if ($null -eq $UserSessions) {
            write-verbose "Could not pull back user sessions from the NetScaler - returning -1"
            $UserSessions = -1
        }
        
        return $UserSessions
    }


}
