function Test-Series {
    <#   
.SYNOPSIS   
    Checks the ports and services of a Windows Server.
.DESCRIPTION 
    Checks the ports and services of a Windows Server.  This is mainly used in unit testing to validate 
    the test suites before production. The basic flow is:
    Test Connectivity (ICMP) -> Test Ports & Services -> Test Additional Checks
    A failure at a previous state will assume failure further down and stop tests.  We don't care if a 
    SSL cert check is valid if one of the dependant ports is down. This is subject to change.  
    Not all Test-Series will have additional checks, but this is a placeholder.
    A side effect of function is, if the Influx section is configured, we will format the output for it
    in prep.  A Basic configuration is provided. 
.PARAMETER JSONConfigFilename
    Specify path to your config file to run checks against.  This would be your EUCMonitoring.json, or your
    test configs.  Specifying a JSONConfigFilename override any ConfigObject passed to it.  
.PARAMETER ConfigObject
    Specifies the ports to run checks against.  This should already be in the target location.

.NOTES
    Current Version:        1.0
    Creation Date:          14/05/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough         1.0             17/05/2018          Function Creation
    
.EXAMPLE
    Test-Template -JSonConfigFilename "C:\Monitoring\EUCMonitoring.json"
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline, Mandatory = $true)][string]$JSONConfigFilename,
        [Parameter(ValueFromPipeline, Mandatory = $true)][string]$SeriesName
    )
    # There's probably a better way of ensuring one or the other works better.  

    # XXX CHANGEME XXX
    Write-Verbose "Starting Test-Series on $SeriesName."
    # Initialize Empty Results
    Write-Verbose "Initializing Results..."
    $Results = @()

    Write-Verbose "Loading config from $JSonConfigFilename"
    # Set up tests
    if ( test-path $JSONConfigFilename ) {
        $StartTime = (Get-Date)

        try {
            $ConfigObject = Get-Content -Raw -Path $JSONConfigFilename | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            throw "Error reading JSON.  Please Check File and try again."
        }
    }
    else {
        Write-Verbose "Error opening JSON. Please Check File and try again."
        return 
    }
  

    
    $Config = $ConfigObject.$Series
    if ( $null -eq $Config ) {
        Write-Verbose "Unable to find $Series series in $JSonConfigFilename. We shouldn't get here."
        return $Results
    }
   

    # Make sure we're allowed to run this test. 
    if ( ($true -eq $Config.Test) -or ("yes" -eq $Config.Test) ) {

        # For the Series that have no servers configured, we will populate servers 
        # with either global values, or amongst sets.  I'd like to eventually be able
        # to have multiple sites definable.  To do this, we let 
        if ( $Series -eq "Worker" ) {

            Write-Verbose "Invoking Worker Targets"

            # If someone populates this, they know which servers to hit.
            if ( $null = $Config.Servers ) { $Config.Servers = @() }

            # Troll the Config object, get all the XdSite definitions from the workers
            # and pick either primary or secondary server as the controller that all the 
            # checks will be done from.  Add Controller to $Servers, so that for multiple
            # sites the checks will be done to all up servers.  This will then funnel down
            # to the foreach loop.  

            # RdsSites in place for eventual support. 

            foreach ( $XdSite in $Config.XdSites ) {
                # Test Connection, add the first controller that responds to Servers
                # as well as XdControllers
                $Controller = ""
            
                if ( (Connect-Server $XdSite.PrimaryController ) -eq "Successful" ) {
                    $Controller = $XdSite.PrimaryController 
                    $Config.Servers += $Controller
                    $XdControllers += $Controller
                    Write-Verbose "Adding XD Controller $XDController"
                }
                elseif ( (Connect-Server $XdSite.SecondaryController) -eq "Successful") {
                    $Controller = $XdSite.SecondaryController       
                    $Config.Servers += $Controller
                    $XdControllers += $Controller
                    Write-Verbose "Adding XD Controller $XDController"             
                }
                else {                    
                    Write-Verbose "Could not connect to any controllers in $XDSite"
                    $Errors += "Could not connect to any controllers in $XDSite."
                }
            }

            <# - Not valid yet... but soon hopefully.
            foreach ( $RdsSite in $Config.RdsSites  ) {
                # Test connection, add the first controller that responds to Servers
                # as well as RdsServers
            }
            #>
            

        } #END WORKER
    
        # This loops over each computer in $Config.Servers, checks the connection,
        # tests all ports defined in config, all services defined in the config,
        # and if none of those tests fail, it will do the additional checks.
        # Worker Series will populate with just the servers, but no ports or 
        # Services, so they will be checks only.  
        foreach ($ComputerName in $Config.Servers) {
            # State can be UP / DEGRADED / DOWN
            $State = "UP"
            $PortsUp = @()
            $PortsDown = @()
            $ServicesUp = @()
            $ServicesDown = @()
            $ChecksUp = @()     # These are additional and might not be used. 
            $ChecksDown = @()   # These are additional and might not be used.
            $ChecksData = @()
            $Errors = @()

            if ((Connect-Server $ComputerName) -eq "Successful") {
               
                # Ports
                foreach ($Port in $Config.Ports) { 
                    if ((Test-NetConnection $ComputerName $Port).open -eq "True") {
                        $PortsUp += $Port   
                    }
                    else {
                        $State = "DEGRADED"
                        $PortsDown += $Port
                        $Errors += "$Port closed"
                    }
                }
    
                # Windows Services
                foreach ($Service in $Config.Services) {
                    $CurrentServiceStatus = Test-Service $ComputerName $Service
                    If ($CurrentServiceStatus -eq "Running") {
                        $ServicesUp += $Service
                    }
                    else {
                        $State = "DEGRADED"
                        $ServicesDown += $Service
                        $Errors += "$Service not running"
                    } 
                } 


                # JSON file should reflect this configuration.  Interate over checks, test, and put in 
                # correct group.  Checks are pass/fail.  Errors array holds the detail for review
                <#
                if ("ValidateHTTPSCert" -in $Config.Checks) {
                     if ( Test-ValidCert -Target $ComputerName -port 443 ) { 
                        $ChecksUp += "ValidCert"
                    } 
                    else {
                        Write-Verbose "$ComputerName state degraded. Port 443 Cert not valid"
                        $State = "DEGRADED"
                        $ChecksDown += "ValidCert"
                        $Errors += "$ComputerName - Port 443 Cert not valid"
                    }
                
                #>
                
                # Tests will return true or false, which will determine checkup or checkdown. 
                # If it cannot invoke a check, it will create an error and be placed in checkdown.
                # Each check should be able to create their own influx data using the series
                # information.  

                if ( $State -eq "UP") {
                    # This section, you'll probably end up copying and 
                    # XXX CHANGEME XXX 
                    foreach ($Check in $Config.Checks) {

                        $CheckName = $Check.PSObject.Properties.Name
                        $CheckValue = $Check.PSObject.Properties.Name

                        $Success = $false
                        $Values = @()
                
                        switch ($CheckName) {
                            # XenDesktop Checks
                            # Worker Checks
                            "XdDesktop" { 
                                if ( $ComputerName -in $XdControllers ) { 
                                    $Success, $Values = Test-XdDesktop $ComputerName $Check.BootThreshold $Check.HighLoad
                                }
                            }
                            "XdServer" {
                                if ( $ComputerName -in $XdControllers ) { 
                                    $Success, $Values = Test-XdServer $ComputerName $Check.BootThreshold $Check.HighLoad 
                                }
                            }
                            "XdSessionInfo" {
                                if ( $ComputerName -in $XdControllers ) {
                                    $Success, $Values = Test-XdSessions $ComputerName 
                                }
                            }

                            # License Checks
                            "XdLicense" { 
                                $Success, $Values = Test-XdLicense $ComputerName 
                            }

                            # Site/Env Checks
                            "XdDeliveryGroupHealth" { 
                                if ( $true -eq $CheckValue ) { 
                                    $Success, $Values = Test-XdDeliveryGroupHealth $ComputerName 
                                }
                            }
                            "XdCatalogHealth" { 
                                if ( $true -eq $CheckValue ) {
                                    $Success, $Values = Test-XdCatalogsHealth $ComputerName
                                }
                            }
                            "XdHypervisorHealth" { 
                                if ( $true -eq $CheckValue ) {
                                    $Success, $Values = Test-XdHypervisorHealth $ComputerName
                                }
                            }
                                    
                            # Netscaler Checks
                            "Netscaler" {
                                $Success, $Values = Test-Netscaler $ComputerName $CheckValue.Username $CheckValue.Password
                            }
                            "NetscalerGateway" { 
                                $Success, $Values = Test-NSGateway $ComputerName $CheckValue.Username $CheckValue.Password
                            }

                            # URL Checks
                            "HTTPUrl" { 
                                
                                $Success, $Values = Test-URL "http://$($ComputerName):$($CheckValue.Port)$($CheckValue.Path)"
                                

                                <#

                                            "HTTPUrl": {
                "Ports": [ 80 ],
                "Path": "/Citrix/StoreWeb"
            },
            "HTTPSUrl": {
                "Ports": [ 443 ],
                "Path": "/Citrix/StoreWeb"
            }, 
            #>

                            }
                            "HTTPSUrl" { 
                                $Success, $Values = Test-URL "https://$($ComputerName):$($CheckValue.Port)$($CheckValue.Path)"
                            }
                            "ValidCert" { 
                                $Success, $Values = Test-ValidCert $ComputerName $CheckValue.Port
                            }

                            # PVS
                            "PVSSite" { }
                            "PVSFarm" { }

                            Default { }
                        }
           
                        # Validate Success
                        if ( $true -eq $Success ) {     
                            $ChecksUp += $CheckName
                        } 
                        else { 
                            $ChecksDown += $CheckName
                            $Errors += "$CheckName failed"
                            $State = "DEGRADED"
                        }         
                            
                        if ( $null -ne $Values ) {
                            # Do I traverse Values to find Errors?  
                            # XXX CHANGEME XXX 
                            if ( $null -ne $Values.Errors ) {
                                $Errors += $Values.Errors
                                $State = "DEGRADED"
                            }
                            $ChecksData += [PSCustomObject]@{
                                CheckName = $CheckName
                                Values    = $Values
                            }
                        }
                    }
                } 
                # State is DEGRADED, we will not run additional checks.
                else {    
                    foreach ($Check in $Config.Checks) {
                        $ChecksDown += $Check.PSObject.Properties.Name
                    }
                }


                # Finalize State by making sure if no tests passed, it's the same as being down. If degraded,
                # There's no need to do further checks 
                # XXX CHANGEME XXX - Validate this is correct.  
                if ( "DEGRADED" -eq $State ) {
                    if ( ($null -eq $ServicesUp) -and ($null -eq $PortsUp) -and ($null -eq $ChecksUp) ) {
                        Write-Verbose "$ComputerName is down."
                        $State = "DOWN"
                        # This is probably redundant, but good housekeeping. 
                        $PortsDown = $Config.Ports
                        $ServicesDown = $Config.Services
                        $ChecksDown = $Config.Checks
                        $Errors += "$ComputerName is down."
                    } 
                }
            }
            # Server is down - not responding to ping
            # XXX CHANGEME XXX - Anything else to be set / returned? 
            else {
                Write-Verbose "$ComputerName is down."
                $State = "DOWN"
                $PortsDown += $Ports
                $ServicesDown += $Services
                    
                foreach ($Check in $Config.Checks) {
                    $ChecksDown += $Check.PSObject.Properties.Name
                }
                $Errors += "$ComputerName is down." 
            }
        
            # XXX CHANGEME XXX - Did you alter results?  Was there a good reason?
            $results += [PSCustomObject]@{
                'ComputerName' = $ComputerName
                'State'        = $State
                'PortsUp'      = $PortsUp
                'PortsDown'    = $PortsDown
                'ServicesUp'   = $ServicesUp
                'ServicesDown' = $ServicesDown
                'ChecksUp'     = $ChecksUp
                'ChecksDown'   = $ChecksDown
                'ChecksData'   = $ChecksData
                'Errors'       = $Errors
            }
        } 

        $EndTime = (Get-Date)
        Write-Verbose "Test-Series for $Series finished."
        Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalMinutes) Minutes"
        Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalSeconds) Seconds"
    } #else we didn't really want to test, so we don't populate results, which will return an empty array.

    return $results
}