function Test-FAS {
    <#   
.SYNOPSIS   
    Tests Citrix Federated Authentication Server Functionailty.
.DESCRIPTION 
    Tests Citrix Federated Authentication Server Functionailty ..
    Currently Testing
        FAS Server Availability
        All Services passed into the module     
.PARAMETER FASServers 
    Comma Delimited List of FAS Servers to check
.PARAMETER FASPortString 
    TCP Port to use for FAS Connectivity Tests
.PARAMETER FASServices 
    FAS Services to check
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
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$FASServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$FASPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$FASServices,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$OutputFile

    )

    # Initialize Arrays and Variables
    $FASServerUp = 0
    $FASServerDown = 0
    Write-Verbose "Variables and Arrays Initalized"

    # Get FAS Server Comma Delimited List 
    $FASServers = $FASServers.Split(",")
    $FASServices = $FASServices.Split(",")
    Write-Verbose "Read in FAS Details"
    Write-Verbose "FAS Servers: $FASServers"
    Write-Verbose "FAS Ports: $FASPortString" 
    Write-Verbose "FAS Services: $FASServices"

    foreach ($FASServer in $FASServers) {

        # Check that the FAS Server is up
        if ((Connect-Server $FASServer) -eq "Successful") {
			
            # Server is up and responding to ping
            Write-Verbose "$FASServer is online and responding to ping" 

            # Check the FAS Server Port
            if ((Test-NetConnection $FASServer $FASPortString).open -eq "True") {

                # FAS port is up and running
                Write-Verbose "$FASServer Certificate Request and Issuance Port is up: Port - $FASPortString"

                # Check all critical services are running on the FAS Server
                # Initalize Pre loop variables and set Clean Run Services to Yes
                $ServicesUp = "Yes"
                $ServiceError = ""

                # Check Each Service for a Running State
                foreach ($Service in $FASServices) {
                    $CurrentServiceStatus = Test-Service $FASServer $Service
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

                # Check for ALL services running, if so mark FAS Server as UP, if not Mark as down and increment down count
                if ($ServicesUp -eq "Yes") {
                    # The FAS Server and all services tested successfully - mark as UP
                    Write-Verbose "$FASServer is up and all Services are running"
                    $FASServerUp++
                }
                else {
                    # There was an error with one or more of the services
                    Write-Verbose "$FASServer Service error - $ServiceError - is degraded or stopped."
                    "$FASServer Service error - $ServiceError - is degraded or stopped." | Out-File $ErrorFile -Append
                    $FASServerDown++
                }
                
            }
            else {
                # FAS Port is down - mark down, error log and increment down count
                Write-Verbose "$FASServer Certificate Request and Issuance Port is down - Port - $FASPortString"
                "$FASServer Certificate Request and Issuance Port is down - Port - $FASPortString" | Out-File $ErrorFile -Append
                $FASServerDown++
            }

        }
        else {
            # FAS Server is down - not responding to ping
            Write-Verbose "$FASServer is down" 
            "$FASServer is down"  | Out-File $ErrorFile -Append
            $FASServerDown++
        }
    }

    # Write Data to Output File
    Write-Verbose "Writing FAS Server Data to output file"
    "FASServer,$FASServerUp,$FASServerDown" | Out-File $OutputFile
}
