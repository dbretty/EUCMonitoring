function Test-Template {
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
    Adam Yarborough         1.0             22/02/2018          Function Creation
    
.EXAMPLE
    Test-Template -JSonConfigFilename "C:\Monitoring\EUCMonitoring.json"
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline,Mandatory=$true)][string]$SeriesName,
        [Parameter(ValueFromPipeline,Mandatory=$true)][string]$JSONConfigFileName
 #       [Parameter(ValueFromPipeline)]$ConfigObject
    )
    # There's probably a better way of ensuring one or the other works better.  

    # XXX CHANGEME XXX
    Write-Verbose "Starting Test-Template."
    # Initialize Empty Results
    $Results = @()

    # Set up tests
   

    # Including a JSONFileName has higher precedence than passing a loaded. 
 #   if ( $JSONConfigFilename ) {
 #       $ConfigObject = Get-Content -Raw -Path $JSONConfigFilename | ConvertFrom-Json
 #   }    

    # XXX CHANGEME XXX
    # Set $Config to the proper location.  This should be passed 
    $Config = $Series.Path
    $Config = $ConfigObject.$Series

    # Set the path to your test area. 
    #$Config = $JSONConfig.Citrix.Controllers
   

    # Make sure we're allowed to run this test. 
    if ( ($true -eq $Config.Test) -or ("yes" -eq $Config.Test) ) {

        # For the Series that have no servers configured
        if ( $Series -eq "Worker" ) {
            $State = "UP"
            $PortsUp = @()
            $PortsDown = @()
            $ServicesUp = @()
            $ServicesDown = @()
            $ChecksUp = @()     # These are additional and might not be used. 
            $ChecksDown = @()   # These are additional and might not be used.
            $Errors = @()

            Write-Verbose 
        }

        # This section will skip the "Worker"/"CitrixEnvironment"
        foreach ($ComputerName in $Config.Servers) {
            # State can be UP / DEGRADED / DOWN
            $State = "UP"
            $PortsUp = @()
            $PortsDown = @()
            $ServicesUp = @()
            $ServicesDown = @()
            $ChecksUp = @()     # These are additional and might not be used. 
            $ChecksDown = @()   # These are additional and might not be used.
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
                # Okay, so this is some magic.  We're gonna dynamically invoke functions using the 
                # check name.  If the check name is "HTTPUrl", we'll call Test-HTTPUrl and pass 
                # parameters.  Each check will know what series it's in, as well as have a config
                # object referenced.  
                # Tests will return true or false, which will determine checkup or checkdown. 
                # If it cannot invoke a check, it will create an error and be placed in checkdown.
                # Each check should be able to create their own influx data using the series
                # information.  

                if ( $State -eq "UP") {
                    # This section, you'll probably end up copying and 
                    # XXX CHANGEME XXX 
                    foreach ($Check in $Config.Checks) {
                        $CheckName = $Check.PSObject.Properties.Name
                        $CheckFunc = "Test-$($CheckName)"
                        if (Test-CommandExists $CheckFunc) {
                            $Success = Invoke-Expression "$CheckFunc $Series $JSONConfigFilename $ComputerName"
                        
                        # Validate Success
                            if ( $true -eq $Success ) { 
                                $ChecksUp += "$CheckName"
                            }

                            # Assume Error if we got this far. 
                            else { 
                                # XXX CHANGEME XXX
                                $ChecksDown += "$CheckName"
                                # XXX CHANGEME XXX
                                $Errors += "$CheckName failed"
                                $State = "DEGRADED"
                                         }         
                                                }
                                                else { $Errors += "$CheckFunc does not exist"}
                        
                    }

                    <#
                    Check-HTTPUrl (host, port, path)
                    Check-HTTPSUrl (host, port, path)
                    Check-ValidCert (host, port)
                    Check-XenServer (host, port, creds)
                    Check-Netscaler
                    Check-PVSsite ( , , )

                    Each of these invocations looks like  
                    Test-CheckName($Series.CheckName, $ConfigObject, $ComputerName)
                    #>
                } 
                else {
                    # State is DEGRADED, we will not run additional checks.
                    $ChecksDown = $Config.Checks
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
                $ChecksDown += $Checks
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
                'Errors'       = $Errors
            }
        }
    

        #else we didn't really want to test, so we don't populate results, which will return an empty array.
    }
    return $results
}