function Test-UPS {
    <#   
.SYNOPSIS   
    Tests Citrix Universal Print Server Functionailty.
.DESCRIPTION 
    Tests Citrix Universal Print Server Functionailty ..
    Currently Testing
        UPS Server Availability
        UPS Data Stream CGP Port Connectivity
        All Services passed into the module     
.PARAMETER UPSServers 
    Comma Delimited List of UPS Servers to check
.PARAMETER UPSPortString 
    TCP Port to use for UPS Connectivity Tests
.PARAMETER UPSServices 
    UPS Services to check
.PARAMETER ErrorFile 
    Infrastructure Error File to Log To
.PARAMETER OutputFile 
    Infrastructure OutputFile   
.NOTES
    Current Version:        1.0
    Creation Date:          16/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    James Kindon            1.0             16/03/2018          Function Creation
.EXAMPLE
    None Required
#> 

    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$UPSServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$UPSPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$UPSServices,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$OutputFile

    )

    # Initialize Arrays and Variables
    $UPSServerUp = 0
    $UPSServerDown = 0
    Write-Verbose "Variables and Arrays Initalized"

    # Get UPS Server Comma Delimited List 
    $UPSServers = $UPSServers.Split(",")
    $UPSServices = $UPSServices.Split(",")
    Write-Verbose "Read in UPS Details"
    Write-Verbose "UPS Servers: $UPSServers"
    Write-Verbose "UPS Ports: $UPSPortString" 
    Write-Verbose "UPS Services: $UPSServices"

    foreach ($UPSServer in $UPSServers) {

        # Check that the UPS Server is up
        if ((Connect-Server $UPSServer) -eq "Successful") {
			
            # Server is up and responding to ping
            Write-Verbose "$UPSServer is online and responding to ping" 

            # Check the UPS Server Port
            if ((Test-NetConnection $UPSServer $UPSPortString).open -eq "True") {

                # UPS Data Stream CGP port is up and running
                Write-Verbose "$UPSServer Data Stream CGP Port is up: Port - $UPSPortString"

                # Check all critical services are running on the UPS Server
                # Initalize Pre loop variables and set Clean Run Services to Yes
                $ServicesUp = "Yes"
                $ServiceError = ""

                # Check Each Service for a Running State
                foreach ($Service in $UPSServices) {
                    $CurrentServiceStatus = Test-Service $UPSServer $Service
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

                # Check for ALL services running, if so mark UPS Server as UP, if not Mark as down and increment down count
                if ($ServicesUp -eq "Yes") {
                    # The UPS Server and all services tested successfully - mark as UP
                    Write-Verbose "$UPSServer is up and all Services are running"
                    $UPSServerUp++
                }
                else {
                    # There was an error with one or more of the services
                    Write-Verbose "$UPSServer Service error - $ServiceError - is degraded or stopped."
                    "$UPSServer Service error - $ServiceError - is degraded or stopped." | Out-File $ErrorFile -Append
                    $UPSServerDown++
                }
                
            }
            else {
                # UPS Data Stream Agent Port is down - mark down, error log and increment down count
                Write-Verbose "$UPSServer Data Stream CGP Port is down - Port - $UPSPortString"
                "$UPSServer Data Stream CGP Port is down - Port - $UPSPortString" | Out-File $ErrorFile -Append
                $UPSServerDown++
            }

        }
        else {
            # UPS Server is down - not responding to ping
            Write-Verbose "$UPSServer is down" 
            "$UPSServer is down"  | Out-File $ErrorFile -Append
            $UPSServerDown++
        }
    }

    # Write Data to Output File
    Write-Verbose "Writing UPS Server Data to output file"
    "UPSServer,$UPSServerUp,$UPSServerDown" | Out-File $OutputFile
}
