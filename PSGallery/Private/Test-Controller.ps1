function Test-Controller {
    <#   
.SYNOPSIS   
    Tests Citrix XenDesktop Controllers Functionailty.
.DESCRIPTION 
    Tests Citrix XenDesktop Controllers Functionailty..
    Currently Testing
        Broker Availability
        Broker Port Connectivity
        All Services passed into the module
        Site and Zone Avability   
.PARAMETER Controllers 
    Comma Delimited List of Controllers to check
.PARAMETER ControllerPortString 
    TCP Port to use for Controller Connectivity Tests
.PARAMETER ControllerServices 
    Controller Services to check
.PARAMETER ErrorFile 
    Infrastructure Error File to Log To 
.NOTES
    Current Version:        1.1
    Creation Date:          22/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    James Kindon            1.0             27/03/2017          Function Creation
    David Brett             1.1             22/02/2018          Updated to reflect new framework and added details for getting site availability
    David Brett             1.2             29/03/2018          Return Object
.EXAMPLE
    None Required
#> 

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Controllers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ControllerPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ControllerServices,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile
    )

    #Create array with results
    $results = @()

    # Load the Citrix Broker Powershell SDK
    $ControllerSnap = add-pssnapin citrix*
    $ControllerSnap = get-pssnapin citrix*

    if ($null -eq $ControllerSnap) {
        Write-error "XenDesktop Powershell Snapin Load Failed - No XenDesktop Brokering SDK Found"
        Write-error "Cannot Load XenDesktop Powershell SDK"
    } else {
        Write-Verbose "XenDesktop Powershell SDK Snapin Loaded"
    }

    # Initialize Arrays and Variables
    Write-Verbose "Variables and Arrays Initalized"

    Write-Verbose "Read in Controller List"
    Write-Verbose "Controllers: $Controllers"
    Write-Verbose "Controller Port: $ControllerPortString" 
    Write-Verbose "Controller Services: $ControllerServices"

    foreach ($Controller in $Controllers) {

        # Tests
        $ping = $false
        $ctrbrokerport = $false
        $ctrservices = $false

        # Check that the Controller is up
        if ((Connect-Server $Controller) -eq "Successful") {
			
            # Server is up and responding to ping
            Write-Verbose "$Controller is up" 
            $ping = $true

            # Check the Brokering Port
            if ((Test-NetConnection $Controller $ControllerPortString).open -eq "True") {

                # Controller broker port is up and running
                Write-Verbose "$Controller Broker Port is up: Port - $ControllerPortString"
                $ctrbrokerport = $true
                
                if ($null -eq $ControllerSnap) {
                    $SiteName = "Unknown - Citrix SDK Not Found"
                    Write-Verbose "$Controller Site: $SiteName"
                } else {
                    # Get Broker Site Information for Error Logging
                    $site = Get-BrokerSite -AdminAddress $Controller
                    $SiteName = $site.Name
                    Write-Verbose "$Controller Site: $SiteName"
                }

                # Check all critical service are running on the controller
                # Initalize Pre loop variables and set Clean Run Services to Yes
                $ServicesUp = "Yes"
                $ServiceError = ""

                # Check Each Service for a Running State
                foreach ($Service in $ControllerServices) {
                    $CurrentServiceStatus = Test-Service $Controller $Service
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

                # Check for ALL services running, if so mark Controller as UP, if not Mark as down and increment down count
                if ($ServicesUp -eq "Yes") {
                    # The Controller and all services tested successfully - mark as UP
                    Write-Verbose "$Controller is up and all Services and running"
                    $ctrservices = $true
                }
                else {
                    # There was an error with one or more of the services
                    Write-Verbose "$Controller Service error - $ServiceError - is degraded or stopped. Site: $siteName"
                    "$Controller Service error - $ServiceError - are degraded or stopped. Site: $siteName" | Out-File $ErrorFile -Append
                    $ctrservices = $false
                }
                
            }
            else {
                # Controller Broker Port is down - mark down, error log and increment down count
                Write-Verbose "$Controller Broker Port is down - Port - $ControllerPortString"
                "$Controller Broker Port is down - Port - $ControllerPortString" | Out-File $ErrorFile -Append
                $ctrbrokerport = $false
            }

        }
        else {
            # Controller is down - not responding to ping
            Write-Verbose "$Controller is down" 
            "$Controller is down"  | Out-File $ErrorFile -Append
            $ping = $false
        }

        # Add results to array
        $results += [PSCustomObject]@{
            'Server'                = $Controller
            'Site'                  = $SiteName
            'Ping'                  = $ping
            'BrokerPort'            = $ctrbrokerport
            'ControllerServices'    = $ctrservices
        }
    }

    #returns object with test results
    return $results
}
