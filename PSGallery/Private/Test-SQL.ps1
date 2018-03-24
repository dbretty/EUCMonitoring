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
.PARAMETER OutputFile 
    Infrastructure OutputFile   
.NOTES
    Current Version:        1.0
    Creation Date:          21/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    James Kindon            1.0             21/03/2018          Function Creation
.EXAMPLE
    None Required
#> 

    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$SQLServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$SQLPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$SQLServices,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$OutputFile

    )

    # Initialize Arrays and Variables
    $SQLServerUp = 0
    $SQLServerDown = 0
    Write-Verbose "Variables and Arrays Initalized"

    Write-Verbose "Read in SQL Details"
    Write-Verbose "SQL Servers: $SQLServers"
    Write-Verbose "SQL Ports: $SQLPortString" 
    Write-Verbose "SQL Services: $SQLServices"

    foreach ($SQLServer in $SQLServers) {

        # Check that the SQL Server is up
        if ((Connect-Server $SQLServer) -eq "Successful") {
			
            # Server is up and responding to ping
            Write-Verbose "$SQLServer is online and responding to ping" 

            # Check the SQL Server Port
            if ((Test-NetConnection $SQLServer $SQLPortString).open -eq "True") {

                # SQL Server port is up and running
                Write-Verbose "$SQLServer Port is up: Port - $SQLPortString"

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
                    $SQLServerUp++
                }
                else {
                    # There was an error with one or more of the services
                    Write-Verbose "$SQLServer Service error - $ServiceError - is degraded or stopped."
                    "$SQLServer Service error - $ServiceError - is degraded or stopped." | Out-File $ErrorFile -Append
                    $SQLServerDown++
                }
                
            }
            else {
                # SQL Server Port is down - mark down, error log and increment down count
                Write-Verbose "$SQLServer LDAP Port is down - Port - $SQLPort"
                "$SQLServer Port is down - Port - $SQPPort" | Out-File $ErrorFile -Append
                $SQLServerDown++
            }

        }
        else {
            # SQL Server is down - not responding to ping
            Write-Verbose "$SQLServer is down" 
            "$SQLServer is down"  | Out-File $ErrorFile -Append
            $SQLServerDown++
        }
    }

    # Write Data to Output File
    Write-Verbose "Writing SQL Server Data to output file"
    "SQLServer,$SQLServerUp,$SQLServerDown" | Out-File $OutputFile
}
