function Test-XenServer {
    <#   
.SYNOPSIS   
    Checks the Status of the XenServer Pools Passed In
.DESCRIPTION 
    Checks the Status of the XenServer Pools Passed In
.PARAMETER PoolMasters 
    Comma Delimited List of XenServer Pool Masters to check
.PARAMETER ConnectionPort 
    TCP Port to use for XenServer Connectivity Tests
.PARAMETER ErrorFile 
    Infrastructure Error File to Log To
.PARAMETER XenUserName 
    XenServer Username
.PARAMETER XenPassword 
    XenServer Password
.NOTES
    Current Version:        1.0
    Creation Date:          22/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             22/02/2018          Function Creation
    Ryan Butler             1.1             28/03/2018          Returns object
    David Brett             1.2             16/06/2018          Updated for Object Model
.EXAMPLE
    None Required
#>
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$PoolMaster,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$XenUserName,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][System.Security.SecureString]$XenPassword
    )

    #Create array with results
    $Results = @()
    $Errors = @()

    # Convert Secure Password to Standard Text
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($XenPassword)
    $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    # Import XenServer SDK
    import-module Xen*
    $xenTest = get-module xen*
    if ($null -eq $xentest) {
        write-verbose "XenServer checks are enabled but no XenServer SDK Found"
        $Errors += "XenServer checks are enabled but no XenServer SDK Found"
    }
    else {
        Write-Verbose "XenServer SDK Imported Sucessfully"
        Write-Verbose "XenServer Pool Master: $PoolMaster"
        Write-Verbose "Management Port: 80"

        $HostsUp = 0
        $HostsDown = 0


        $Session = Connect-XenServer $PoolMaster -Port 80 -UserName $XenUserName -Password $UnsecurePassword
        Write-Verbose "Connecting to XenServer Pool Using PoolMaster $PoolMaster"

        $XenHosts = Get-XenHost

        # Loop Through Each Host and Check Availability and Management Access
        foreach ($XenHost in $XenHosts) {

            # Get the HostName and IP Addressd for the XenServer Host
            $XenHostName = $XenHost.hostname
            $XenIP = $XenHost.address
            Write-Verbose "XenServer Details - $XenHostName / $XenIP"

            if ((Connect-Server $XenIP) -eq "Successful") {
                Write-Verbose "XenServer Host - $XenHostName is up"

                # If Host Management Port is UP log to Console and Increment UP Port Count
                if (Test-NetConnection -ComputerName $XenIP -Port 80) {
                    Write-Verbose "$XenHostName Management Port is up: Port - 80"
                    $HostsUp ++
                }
                else {
                    Write-Verbose "$XenHostName Management Port is down - Port - $ConnectionPort" 
                    $Errors += "$XenHostName Management Port is down"
                    $HostsDown ++
                }
            }
            else {
                Write-Verbose "XenServer Host - $XenHostName is down"
                $Errors += "XenServer Host - $XenHostName is down"
                $HostsDown ++
            }
        }
        Disconnect-XenServer -Session $session

        $results += [PSCustomObject]@{
            'PoolMaster' = $poolmaster
            'HostsUp' = $HostsUp
            'HostsDown' = $HostsDown
        }

    #Returns test results
    $Results += $Errors
    return $results
    
    }

}
