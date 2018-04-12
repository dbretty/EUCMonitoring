function Test-AD {
    <#   
.SYNOPSIS   
    Tests Active Directory Server Functionailty.
.DESCRIPTION 
    Tests Active Directory Servers Functionailty..
    Currently Testing
        AD Domain Controller Availability
        AD LDAP Port Connectivity
        All Services passed into the module     
.PARAMETER ADServers 
    Comma Delimited List of Domain Controllers to check
.PARAMETER ADLDAPPortString 
    TCP Port to use for AD Connectivity Tests
.PARAMETER ADServices 
    AD Services to check
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
    Ryan Butler             1.1             28/03/2018          Returns object
.EXAMPLE
    None Required
#> 
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ADServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ADPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ADServices,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile

    )
    
    #Create array with results
    $results = @()

    Write-Verbose "Read in AD Details"
    Write-Verbose "AD Servers: $ADServers"
    Write-Verbose "AD Ports: $ADPortString" 
    Write-Verbose "AD Services: $ADServices"

    foreach ($ADServer in $ADServers) {

        #Tests
        $ping = $false
        $LDAPport = $false
        $health = "UNHEALTHY"

        # Check that the AD Server is up
        if ((Connect-Server $ADServer) -eq "Successful") {
            $ping = $true
            # Server is up and responding to ping
            Write-Verbose "$ADServer is online and responding to ping" 

            # Check the AD Server Port
            if ((Test-NetConnection $ADServer $ADPortString).open -eq "True") {
                $LDAPport = $true        
                # AD Server port is up and running
                Write-Verbose "$ADServer LDAP Port is up: Port - $ADPortString"

                # Check all critical services are running on the AD Server
                # Initalize Pre loop variables and set Clean Run Services to Yes
                $ServicesUp = "Yes"
                $ServiceError = ""

                # Check Each Service for a Running State
                #services hash table
                $servicesht = @()
                foreach ($Service in $ADServices) {
                    $CurrentServiceStatus = Test-Service $ADServer $Service
                    If ($CurrentServiceStatus -ne "Running") {
                        # If the Service is not running set ServicesUp to No and Append The Service with an error to the error description
                        if ($ServiceError -eq "") {
                            $ServiceError = $Service
                            $CurrentServiceStatus = "UNKNOWN"
                        }
                        else {
                            $ServiceError = $ServiceError + ", " + $Service
                            $CurrentServiceStatus = "UNKNOWN"
                        }
                        $ServicesUp = "no"
                    }
                    $servicesht += [PSCustomObject]@{
                        "Service" = $service
                        "Status" = $CurrentServiceStatus
                    }
                }

                # Check for ALL services running, if so mark AD Server as UP, if not Mark as down and increment down count
                if ($ServicesUp -eq "Yes") {
                    # The AD Server and all services tested successfully - mark as UP
                    Write-Verbose "$ADServer is up and all Services are running"
                    $health = "HEALTHY"
                }
                else {
                    # There was an error with one or more of the services
                    Write-Verbose "$ADServer Service error - $ServiceError - is degraded or stopped."
                    "$ADServer Service error - $ServiceError - is degraded or stopped." | Out-File $ErrorFile -Append
                }
                
            }
            else {
                # AD Server LDAP Port is down - mark down, error log and increment down count
                Write-Verbose "$ADServer LDAP Port is down - Port - $ADPortString"
                "$ADServer LDAP Port is down - Port - $ADPortString" | Out-File $ErrorFile -Append
            }

        }
        else {
            # AD Server is down - not responding to ping
            Write-Verbose "$ADServer is down" 
            "$ADServer is down"  | Out-File $ErrorFile -Append
        }
        #add results to array
        $results += [PSCustomObject]@{
            'Server'   = $ADServer
            'Ping'     = $ping
            'LDAPPort' = $LDAPport
            'Health'   = $health 
            'Services' = $servicesht
        }
    }

    #returns object with test results
    return $results

}
