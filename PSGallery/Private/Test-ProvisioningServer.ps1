function Test-ProvisioningServer {
    <#   
.SYNOPSIS   
    Tests Citrix Provisioning Servers Functionailty.
.DESCRIPTION 
    Tests Citrix  Provisioning Servers Functionailty..
    Currently Testing
        PVS Server Availability
        PVS Management Port Connectivity
        All Services passed into the module     
.PARAMETER ProvisioningServers 
    Comma Delimited List of Provisioning Servers to check
.PARAMETER ProvisioningServerPortString 
    TCP Port to use for Provisioning Server Connectivity Tests
.PARAMETER ProvisioningServerServices 
    Provisioning Server Services to check
.PARAMETER ErrorFile 
    Infrastructure Error File to Log To
.PARAMETER OutputFile 
    Infrastructure OutputFile   
.NOTES
    Current Version:        1.0
    Creation Date:          14/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    James Kindon            1.0             14/03/2018          Function Creation
.EXAMPLE
    None Required
#> 

    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ProvisioningServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ProvisioningServerPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ProvisioningServerServices,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$OutputFile

    )

    # Initialize Arrays and Variables
    $ProvisioningServerUp = 0
    $ProvisioningServerDown = 0
    Write-Verbose "Variables and Arrays Initalized"

    Write-Verbose "Read in Provisioning Server Details"
    Write-Verbose "Provisioning Server Farm: $ProvisioningServerFarm"
    Write-Verbose "Provisioning Server Site: $ProvisioningServerSite"
    Write-Verbose "Provisioning Servers: $ProvisioningServers"
    Write-Verbose "Provisioning Server Ports: $ProvisioningServerPortString" 
    Write-Verbose "Provisioning Server Services: $ProvisioningServerServices"

    foreach ($ProvisioningServer in $ProvisioningServers) {

        # Check that the Provisioning Server is up
        if ((Connect-Server $ProvisioningServer) -eq "Successful") {
			
            # Server is up and responding to ping
            Write-Verbose "$ProvisioningServer is online and responding to ping" 

            # Check the Provisioning Server Port
            if ((Test-NetConnection $ProvisioningServer $ProvisioningServerPortString).open -eq "True") {

                # PVS Server port is up and running
                Write-Verbose "$ProvisioningServer Server Port is up: Port - $ProvisioningServerPortString"

                # Check all critical services are running on the PVS Server
                # Initalize Pre loop variables and set Clean Run Services to Yes
                $ServicesUp = "Yes"
                $ServiceError = ""

                # Check Each Service for a Running State
                foreach ($Service in $ProvisioningServerServices) {
                    $CurrentServiceStatus = Test-Service $ProvisioningServer $Service
                    If ($CurrentServiceStatus -ne "Running") {
                        # If the Service is not running set ServicesUp to No and Append The Service with an error to the error description
                        if ($ServiceError -eq "") {
                            $ServiceError = $Service
                        }
                        else {
                            $ServiceError = $ServiceError + ", " + $Service
                        }
                        $ServicesUp = "no"
                    }
                }

                # Check for ALL services running, if so mark Provisioning Server as UP, if not Mark as down and increment down count
                if ($ServicesUp -eq "Yes") {
                    # The Provisioning Server and all services tested successfully - mark as UP
                    Write-Verbose "$ProvisioningServer is up and all Services and running in Site $ProvisioningServerSite in Farm $ProvisioningServerFarm"
                    $ProvisioningServerUp++
                }
                else {
                    # There was an error with one or more of the services
                    Write-Verbose "$ProvisioningServer Service error - $ServiceError - is degraded or stopped."
                    "$ProvisioningServer Service error - $ServiceError - is degraded or stopped." | Out-File $ErrorFile -Append
                    $ProvisioningServerDown++
                }
                
            }
            else {
                # Provisioning Server Broker Port is down - mark down, error log and increment down count
                Write-Verbose "$ProvisioningServer Server Access Port is down - Port - $ProvisioningServerPortString"
                "$ProvisioningServer Server Access Port is down - Port - $ProvisioningServerPortString" | Out-File $ErrorFile -Append
                $ProvisioningServerDown++
            }

        }
        else {
            # Provisioning Server is down - not responding to ping
            Write-Verbose "$ProvisioningServer is down in Site $ProvisioningServerSite in Farm $ProvisioningServerFarm" 
            "$ProvisioningServer is down"  | Out-File $ErrorFile -Append
            $ProvisioningServerDown++
        }
    }

    # Write Data to Output File
    Write-Verbose "Writing Provisioning Server Data to output file"
    "ProvisioningServer,$ProvisioningServerUp,$ProvisioningServerDown" | Out-File $OutputFile
}
