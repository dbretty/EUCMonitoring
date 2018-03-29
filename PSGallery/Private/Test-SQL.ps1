function Test-SQL {
    <#   
.SYNOPSIS   
    Tests SQL Server Functionailty.
.DESCRIPTION 
    Tests SQL Servers Functionailty..
    Currently Testing
        SQL Server Availability
        SQL Port Connectivity
        All Services passed into the module     
.PARAMETER SQLServers 
    Comma Delimited List of Domain Controllers to check
.PARAMETER SQLServerPortString 
    TCP Port to use for SQL Connectivity Tests
.PARAMETER SQLServices 
    SQL Services to check
.PARAMETER ErrorFile 
    Infrastructure Error File to Log To 
.NOTES
    Current Version:        1.0
    Creation Date:          21/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    James Kindon            1.0             21/03/2018          Function Creation
    David Brett             1.1             29/03/2018          Return Object
.EXAMPLE
    None Required
#> 

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$SQLServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$SQLPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$SQLServices,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile
    )

    #Create array with results
    $results = @()

    # Initialize Arrays and Variables
    Write-Verbose "Variables and Arrays Initalized"

    Write-Verbose "Read in SQL Details"
    Write-Verbose "SQL Servers: $SQLServers"
    Write-Verbose "SQL Ports: $SQLPortString" 
    Write-Verbose "SQL Services: $SQLServices"

    foreach ($SQLServer in $SQLServers) {

        # Tests
        $ping = $false
        $sqlport = $false
        $sqlsvc = $false

        # Check that the SQL Server is up
        if ((Connect-Server $SQLServer) -eq "Successful") {
			
            # Server is up and responding to ping
            Write-Verbose "$SQLServer is online and responding to ping" 
            $ping = $true

            # Check the SQL Server Port
            if ((Test-NetConnection $SQLServer $SQLPortString).open -eq "True") {

                # SQL Server port is up and running
                Write-Verbose "$SQLServer Port is up: Port - $SQLPortString"
                $sqlport = $true

                # Check all critical services are running on the SQL Server
                # Initalize Pre loop variables and set Clean Run Services to Yes
                $ServicesUp = "Yes"
                $ServiceError = ""

                # Check Each Service for a Running State
                foreach ($Service in $SQLServices) {
                    $CurrentServiceStatus = Test-Service $SQLServer $Service
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

                # Check for ALL services running, if so mark SQL Server as UP, if not Mark as down and increment down count
                if ($ServicesUp -eq "Yes") {
                    # The SQL Server and all services tested successfully - mark as UP
                    Write-Verbose "$SQLServer is up and all Services are running"
                    $sqlsvc = $true
                }
                else {
                    # There was an error with one or more of the services
                    Write-Verbose "$SQLServer Service error - $ServiceError - is degraded or stopped."
                    "$SQLServer Service error - $ServiceError - is degraded or stopped." | Out-File $ErrorFile -Append
                    $sqlsvc = $false
                }
                
            }
            else {
                # SQL Server Port is down - mark down, error log and increment down count
                Write-Verbose "$SQLServer SQL Port is down - Port - $SQLPortString"
                "$SQLServer Port is down - Port - $SQLPortString" | Out-File $ErrorFile -Append
                $sqlport = $false
            }

        }
        else {
            # SQL Server is down - not responding to ping
            Write-Verbose "$SQLServer is down" 
            "$SQLServer is down"  | Out-File $ErrorFile -Append
            $ping = $false
        }

        # Add results to array
        $results += [PSCustomObject]@{
            'Server'         = $SQLServer
            'Ping'           = $ping
            'SQLPort'        = $sqlport
            'SQLServices'    = $sqlsvc
        }
    }

    #returns object with test results
    return $results

}
