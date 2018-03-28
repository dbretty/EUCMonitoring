function Test-AppV {
    <#   
.SYNOPSIS   
    Tests AppV Publishing Server Functionailty.
.DESCRIPTION 
    Tests AppV Publishing Servers Functionailty..
    Currently Testing
        AppV Publishing Server Availability
        AppV Publishing Port Connectivity
        All Services passed into the module     
.PARAMETER ADServers 
    Comma Delimited List of AppV Publishing Server to check
.PARAMETER ADLDAPPortString 
    TCP Port to use for AppV Publishing Server Connectivity Tests
.PARAMETER AppVServices 
    AD Services to check
.PARAMETER ErrorFile 
    Infrastructure Error File to Log To
.PARAMETER OutputFile 
    Infrastructure OutputFile   
.NOTES
    Current Version:        1.0
    Creation Date:          28/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Wilkinson          1.0             21/03/2018          Function Creation
.EXAMPLE
    None Required
#> 

    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$AppVServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$AppVPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$AppVServices,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$OutputFile

    )

    # Initialize Arrays and Variables
    $AppVServerUp = 0
    $AppVServerDown = 0
    Write-Verbose "Variables and Arrays Initalized"

    Write-Verbose "Read in AppV Details"
    Write-Verbose "AD Servers: $AppVServers"
    Write-Verbose "AD Ports: $AppVPortString" 
    Write-Verbose "AD Services: $AppVServices"

    foreach ($AppVServer in $AppVServers) {

        # Check that the AppV Publishing Server is up
        if ((Connect-Server $AppVServer) -eq "Successful") {
			
            # Server is up and responding to ping
            Write-Verbose "$AppVServer is online and responding to ping" 

            # Check the AppV Publishing Server Port
            if ((Test-NetConnection $AppVServer $AppVPortString).open -eq "True") {

                # AppV Publishing Server port is up and running
                Write-Verbose "$AppVServer LDAP Port is up: Port - $AppVPortString"

                # Check all critical services are running on the AppV Publishing
                # Initalize Pre loop variables and set Clean Run Services to Yes
                $ServicesUp = "Yes"
                $ServiceError = ""

                # Check Each Service for a Running State
                foreach ($Service in $AppVServices) {
                    $CurrentServiceStatus = Test-Service $AppVServer $Service
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

                # Check for ALL services running, if so mark AppV Publishing Server as UP, if not Mark as down and increment down count
                if ($ServicesUp -eq "Yes") {
                    # The AppV Publishing Server and all services tested successfully - mark as UP
                    Write-Verbose "$AppVServer is up and all Services are running"
                    $AppVServerUp++
                }
                else {
                    # There was an error with one or more of the services
                    Write-Verbose "$AppVServer Service error - $ServiceError - is degraded or stopped."
                    "$AppVServer Service error - $ServiceError - is degraded or stopped." | Out-File $ErrorFile -Append
                    $AppVServerDown++
                }
                
            }
            else {
                # AppV Publishing Port is down - mark down, error log and increment down count
                Write-Verbose "$AppVServer LDAP Port is down - Port - $AppVPortString"
                "$AppVServer LDAP Port is down - Port - $AppVPortString" | Out-File $ErrorFile -Append
                $AppVServerDown++
            }

        }
        else {
            # AppV Publishing Server is down - not responding to ping
            Write-Verbose "$AppVServer is down" 
            "$AppVServer is down"  | Out-File $ErrorFile -Append
            $AppVServerDown++
        }
    }

    # Write Data to Output File
    Write-Verbose "Writing AppV Publishing Server Data to output file"
    "AppVServer,$AppVServerUp,$AppVServerDown" | Out-File $OutputFile
}
