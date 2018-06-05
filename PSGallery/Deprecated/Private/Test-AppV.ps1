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
    David Wilkinson         1.0             21/03/2018          Function Creation
    David Brett             1.1             29/03/2018          Return Object
.EXAMPLE
    None Required
#> 

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$AppVServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$AppVPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$AppVServices,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile
    )
    
    #Create array with results
    $results = @()

    # Initialize Arrays and Variables
    Write-Verbose "Variables and Arrays Initalized"

    Write-Verbose "Read in AppV Details"
    Write-Verbose "AppV Servers: $AppVServers"
    Write-Verbose "AppV Ports: $AppVPortString" 
    Write-Verbose "AppV Services: $AppVServices"

    foreach ($AppVServer in $AppVServers) {

        # Tests
        $ping = $false
        $appvport = $false
        $appvsvc = $false

        # Check that the AppV Publishing Server is up
        if ((Connect-Server $AppVServer) -eq "Successful") {
			
            # Server is up and responding to ping
            Write-Verbose "$AppVServer is online and responding to ping" 
            $ping = $true

            # Check the AppV Publishing Server Port
            if ((Test-NetConnection $AppVServer $AppVPortString).open -eq "True") {

                # AppV Publishing Server port is up and running
                Write-Verbose "$AppVServer Port is up: Port - $AppVPortString"
                $appvport = $true

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
                    $appvsvc = $true
                }
                else {
                    # There was an error with one or more of the services
                    Write-Verbose "$AppVServer Service error - $ServiceError - is degraded or stopped."
                    "$AppVServer Service error - $ServiceError - is degraded or stopped." | Out-File $ErrorFile -Append
                    $appvsvc = $false
                }
                
            }
            else {
                # AppV Publishing Port is down - mark down, error log and increment down count
                Write-Verbose "$AppVServer LDAP Port is down - Port - $AppVPortString"
                "$AppVServer Port is down - Port - $AppVPortString" | Out-File $ErrorFile -Append
                $appvport = $false
            }

        }
        else {
            # AppV Publishing Server is down - not responding to ping
            Write-Verbose "$AppVServer is down" 
            "$AppVServer is down"  | Out-File $ErrorFile -Append
            $ping = $false
        }

        # Add results to array
        $results += [PSCustomObject]@{
            'Server'         = $AppVServer
            'Ping'           = $ping
            'AppVPort'       = $appvport
            'AppVService'    = $appvsvc
        }
    }

    #returns object with test results
    return $results
}
