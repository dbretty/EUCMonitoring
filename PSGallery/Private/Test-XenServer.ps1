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
.EXAMPLE
    None Required
#>
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$PoolMasters,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ConnectionPort,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$XenUserName,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][System.Security.SecureString]$XenPassword
    )

    # Convert Secure Password to Standard Text
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($XenPassword)
    $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    # Import XenServer SDK
    import-module Xen*
    $xenTest = get-module xen*
    if ($null -eq $xentest) {
        write-verbose "XenServer checks are enabled but no XenServer SDK Found"
        "XenServer checks are enabled but no XenServer SDK Found" | Out-File $ErrorFile -Append
    }
    else {
        #Create empty array
        $results = @()

        Write-Verbose "XenServer SDK Imported Sucessfully"

        

        # Get XenServer Comma Delimited List and Management Port
        $XenServers = $PoolMasters
        Write-Verbose "Read in XenServer Pool Masters and Management Ports"
        Write-Verbose "XenServer Pool Masters: $XenServers"
        Write-Verbose "Management Port: $ConnectionPort"

        #Loop through Pool Masters pulled from Registry
        Write-Verbose "Looping through XenServer Pool Masters and running monitoring checks"                                                                                                                                                                                                                                          

        foreach ($PoolMaster in $XenServers) {
        # Initialize Arrays and Variables
        $poolmasterPing = $false
        $poolmasterPort = $false
        $HostsUp = 0
        $HostsDown = 0
        $PoolsUp = 0
        $PoolsDown = 0

        Write-Verbose "Variables and Arrays Initalized" 
            # If Pool Master is up log to Console and start the monitoring checks
            if ((Connect-Server $PoolMaster) -eq "Successful") {
                Write-Verbose "PoolMaster - $PoolMaster is up"
                $poolmasterPing = $true
                # Test Management Port Access

                if ((Test-NetConnection $PoolMaster $ConnectionPort).open -eq "True") {
                    $poolmasterPort= $true
                    # Increment Pool Master Up Count
                    $PoolsUp ++

                    # Connect to XenServer Pool
                    [int]$PortInt = [convert]::ToInt32($ConnectionPort, 10)
                    $Session = Connect-XenServer $PoolMaster -Port $PortInt -UserName $XenUserName -Password $UnsecurePassword
                    Write-Verbose "Connecting to XenServer Pool Using PoolMaster $PoolMaster"

                    # Gather Hosts in Pool
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
                            if ((Test-NetConnection $XenIP $ConnectionPort).Open -eq "True") {
                                Write-Verbose "$XenHostName Management Port is up: Port - $ConnectionPort"
                                $HostsUp ++
                            }
                            else {
                                Write-Verbose "$XenHostName Management Port is down - Port - $ConnectionPort" 
                                "$XenHostName Management Port is down" | Out-File $ErrorFile -Append
                                $HostsDown ++
                            }
                        }
                        else {
                            Write-Verbose "XenServer Host - $XenHostName is down"
                            "XenServer Host - $XenHostName is down" | Out-File $ErrorFile -Append
                            $HostsDown ++
                        }
                    }
                    Disconnect-XenServer -Session $session
                }
                else {
                    Write-Verbose "$PoolMaster Management Port is down"
                    "$PoolMaster Management Port is down" | Out-File $ErrorFile -Append
                    $PoolsDown ++
                }
            }
            else {
                Write-Verbose "PoolMaster - $PoolMaster is down"
                "Pool Master - $PoolMaster is down" | Out-File $ErrorFile -Append
                $PoolsDown ++
            }
            $results += [PSCustomObject]@{
                'PoolMaster' = $poolmaster
                'PoolMasterPing' = $poolmasterPing
                'PoolMasterPort' = $poolmasterPort
                'HostsUp' = $HostsUp
                'HostsDown' = $HostsDown
                'PoolsUp' = $PoolsUp
                'PoolsDown' = $PoolsDown
            }
        }
    #Returns test results
    return $results
    }

}
