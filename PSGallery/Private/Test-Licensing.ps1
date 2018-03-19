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
.PARAMETER OutputFile 
    Infrastructure OutputFile
.NOTES
    Current Version:        1.0
    Creation Date:          07/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             07/02/2018          Function Creation
.EXAMPLE
    None Required
#> 

    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$LicenseServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$VendorDaemonPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$LicensePortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$WebAdminPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$SimpleLicenseServicePortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$OutputFile

    )
    # Initialize Arrays and Variables
    $LicenseServerUp = 0
    $LicenseServerDown = 0
    Write-Verbose "Variables and Arrays Initalized"

    # Get License Server Comma Delimited List and Vendor Daemon Port from Registry
    $LicenseServers = $LicenseServers.Split(",")
    Write-Verbose "Read in License Server List and Vendor Daemon Ports"
    Write-Verbose "License Servers: $LicenseServers"
    Write-Verbose "Vendor Daemon Port: $VendorDaemonPortString"
    Write-Verbose "License Port: $LicensePortString"
    Write-Verbose "Web Admin Port: $WebAdminPortString"
    Write-Verbose "Simple License Port: $SimpleLicenseServicePortString"

    # Loop through License Servers 
    Write-Verbose "Looping through License Servers and running monitoring checks"
    foreach ($LicenseServer in $LicenseServers) { 

        # If License Server is UP then log to Console
        if ((Connect-Server $LicenseServer) -eq "Successful") {
            Write-Verbose "$LicenseServer is up"

            # If License Server Vendor Daemon Port is UP log to Console 
            if ((Test-NetConnection $LicenseServer $VendorDaemonPortString).open -eq "True") {
                Write-Verbose "$LicenseServer Vendor Daemon Port is up: Port - $VendorDaemonPortString"
                
                # If License Server License Port is UP log to Console 
                if ((Test-NetConnection $LicenseServer $LicensePortString).open -eq "True") {
                    Write-Verbose "$LicenseServer License Port is up: Port - $LicensePortString"
                    
                    # If License Server Web Admin is UP log to Console 
                    if ((Test-NetConnection $LicenseServer $WebAdminPortString).open -eq "True") {
                        Write-Verbose "$LicenseServer Web Admin is up: Port - $WebAdminPortString"
                        
                        # If License Server Simple License is UP log to Console 
                        if ((Test-NetConnection $LicenseServer $SimpleLicenseServicePortString).open -eq "True") {
                            Write-Verbose "$LicenseServer Simple License Port is up: Port - $SimpleLicenseServicePortString"
                            $LicenseServerUp++
                        }
                        else {
                            Write-Verbose "$LicenseServer Simple License ($SimpleLicenseServicePortString) is down"
                            "$LicenseServer Simple License ($SimpleLicenseServicePortString) is down"  | Out-File $ErrorFile -Append
                            $LicenseServerDown++
                        }
                    }
                    else {
                        Write-Verbose "$LicenseServer Web Admin ($WebAdminPortString) is down"
                        "$LicenseServer Web Admin ($WebAdminPortString) is down"  | Out-File $ErrorFile -Append
                        $LicenseServerDown++
                    }
                }
                else {
                    Write-Verbose "$LicenseServer License Port ($LicensePortString) is down"
                    "$LicenseServer License Port ($LicensePortString) is down"  | Out-File $ErrorFile -Append
                    $LicenseServerDown++
                }
            }
            else {
                Write-Verbose "$LicenseServer Vendor Daemon Port ($VendorDaemonPortString) is down"
                "$LicenseServer Vendor Daemon Port ($VendorDaemonPortString) is down"  | Out-File $ErrorFile -Append
                $LicenseServerDown++
            }
        }
        else {
            Write-Verbose "$LicenseServer is down" 
            "$LicenseServer is down"  | Out-File $ErrorFile -Append
            $LicenseServerDown++
        }
    }
	
    # Write Data to Output File
    Write-Verbose "Writing License Server Data to output file"
    "licensing,$LicenseServerUp,$LicenseServerDown" | Out-File $OutputFile
	
}
