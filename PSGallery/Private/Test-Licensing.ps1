function Test-Licensing {

    <#   
.SYNOPSIS   
    Test Citrix Licensing.
.DESCRIPTION 
    Tests the Citrix Licensing Function.
    Currently Testing
        License Server Availability
        Vendor Daemon and Management Ports
.PARAMETER LicenseServers 
    Comma Delimited List of License Servers to check
.PARAMETER VendorDaemonPortString 
    TCP Port to use for License Server Connectivity Tests
.PARAMETER LicensePortString 
    TCP Port to use for License Server Connectivity Tests
.PARAMETER WebAdminPortString 
    TCP Port to use for License Server Connectivity Tests
.PARAMETER SimpleLicenseServicePortString 
    TCP Port to use for License Server Connectivity Tests
.PARAMETER ErrorFile 
    Infrastructure Error File to Log To
.NOTES
    Current Version:        1.0
    Creation Date:          07/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             07/02/2018          Function Creation
    Ryan Butler             1.1             28/03/2018          Returns object
.EXAMPLE
    None Required
#> 
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$LicenseServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$VendorDaemonPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$LicensePortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$WebAdminPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$SimpleLicenseServicePortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile

    )

    #Create array with results
    $results = @()

    Write-Verbose "Variables and Arrays Initalized"

    Write-Verbose "Read in License Server List and Vendor Daemon Ports"
    Write-Verbose "License Servers: $LicenseServers"
    Write-Verbose "Vendor Daemon Port: $VendorDaemonPortString"
    Write-Verbose "License Port: $LicensePortString"
    Write-Verbose "Web Admin Port: $WebAdminPortString"
    Write-Verbose "Simple License Port: $SimpleLicenseServicePortString"

    # Loop through License Servers 
    Write-Verbose "Looping through License Servers and running monitoring checks"
    foreach ($LicenseServer in $LicenseServers) {
        #Tests
        $ping = $false
        $daemonport = $false
        $LicensePort = $false
        $WebAdminPort = $false
        $SimpleLicPort = $false
        $licensedata = $false  

        # If License Server is UP then log to Console
        if ((Connect-Server $LicenseServer) -eq "Successful") {
            Write-Verbose "$LicenseServer is up"
            $ping = $true
            # If License Server Vendor Daemon Port is UP log to Console 
            if ((Test-NetConnection $LicenseServer $VendorDaemonPortString).open -eq "True") {
                Write-Verbose "$LicenseServer Vendor Daemon Port is up: Port - $VendorDaemonPortString"
                $DaemonPort = $true
                # If License Server License Port is UP log to Console 
                if ((Test-NetConnection $LicenseServer $LicensePortString).open -eq "True") {
                    Write-Verbose "$LicenseServer License Port is up: Port - $LicensePortString"
                    $LicensePort = $true
                    # If License Server Web Admin is UP log to Console 
                    if ((Test-NetConnection $LicenseServer $WebAdminPortString).open -eq "True") {
                        Write-Verbose "$LicenseServer Web Admin is up: Port - $WebAdminPortString"
                        $WebAdminPort = $true
                        # If License Server Simple License is UP log to Console 
                        if ((Test-NetConnection $LicenseServer $SimpleLicenseServicePortString).open -eq "True") {
                            Write-Verbose "$LicenseServer Simple License Port is up: Port - $SimpleLicenseServicePortString"
                            $SimpleLicPort = $true
                            $licensedata = get-XDLicenseCount -LicenseServer $LicenseServer
                        }
                        else {
                            Write-Verbose "$LicenseServer Simple License ($SimpleLicenseServicePortString) is down"
                            "$LicenseServer Simple License ($SimpleLicenseServicePortString) is down"  | Out-File $ErrorFile -Append
                            $SimpleLicPort = $false
                        }
                    }
                    else {
                        Write-Verbose "$LicenseServer Web Admin ($WebAdminPortString) is down"
                        "$LicenseServer Web Admin ($WebAdminPortString) is down"  | Out-File $ErrorFile -Append
                        $WebAdminPort = $false
                    }
                }
                else {
                    Write-Verbose "$LicenseServer License Port ($LicensePortString) is down"
                    "$LicenseServer License Port ($LicensePortString) is down"  | Out-File $ErrorFile -Append
                    $LicensePort = $false
                }
            }
            else {
                Write-Verbose "$LicenseServer Vendor Daemon Port ($VendorDaemonPortString) is down"
                "$LicenseServer Vendor Daemon Port ($VendorDaemonPortString) is down"  | Out-File $ErrorFile -Append
                $DaemonPort = $false
            }
        }
        else {
            Write-Verbose "$LicenseServer is down" 
            "$LicenseServer is down"  | Out-File $ErrorFile -Append
            $ping = $false
        }

        # Add results to array
        $results += [PSCustomObject]@{
            'Server'        = $LicenseServer
            'Ping'          = $Ping
            'daemonport'    = $daemonport
            'LicensePort'   = $LicensePort
            'WebAdminPort'  = $WebAdminPort
            'SimpleLicPort' = $SimpleLicPort
            'LicenseData'   = $Licensedata
        }
    }
    
    #returns object with test results
    return $results
}