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
.PARAMETER JSONFile
    Specify path to your config file to run checks against.  This would be your EUCMonitoring.json, or your
    test configs.  Specifying a JSONFile override any ConfigObject passed to it.  
.PARAMETER Series
    Specifies the name of the Series to run against.  

.NOTES
    Current Version:        1.0
    Creation Date:          14/05/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough         1.0             17/05/2018          Function Creation
    David Brett             1.1             16/06/2018          Updated Switch statement to splat the @params
                                                                Added TestMode as a JSON Parameter to switch between basic and advanced tests
    Adam Yarborough         1.2             20/06/2018          Multi-result ChecksData support, cleanup
                                                                Fixes #24
                                                                Fixes #39
    
.EXAMPLE
    Test-Series -JSONFile "C:\Monitoring\EUCMonitoring.json" Worker
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline, Mandatory = $true)][string]$JSONFile,
        [Parameter(ValueFromPipeline, Mandatory = $true)][string]$Series
    )

    Begin { }
    
    Process { 
       
        Write-Verbose "Starting Test-Series on $Series."
        # Initialize Empty Results
        Write-Verbose "Initializing Results..."
        $Results = @()

        Write-Verbose "Loading config from $JSONFile"
        # Set up tests
        if ( test-path $JSONFile ) {
            $StartTime = (Get-Date)

            try {
                $ConfigObject = Get-Content -Raw -Path $JSONFile | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                throw "Error reading JSON.  Please Check File and try again."
            }
        }
        else {
            Write-Verbose "Error opening JSON. Please Check File and try again."
            return 
        }
      
        Write-Verbose "Loading the configuration for the $Series series"
        $Config = $ConfigObject.$Series
        if ( $null -eq $Config ) {
            Write-Verbose "Unable to find $Series series in $JSONFile. We shouldn't get here."
            return $null
        }
   
        $XdControllers = @()
        $RdsControllers = @()

        # Make sure we're allowed to run this test. 
        if ( $false -eq $Config.Test) { return $null }

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


            if ( $Config.XdSites ) {
                foreach ( $XdSite in $Config.XdSites ) {
                    # Test Connection, add the first controller that responds to Servers
                    # as well as XdControllers
                    $Controller = ""
                    if ( $null -eq $Config.Servers ) {
                        $Config | Add-Member -NotePropertyName Servers -NotePropertyValue @()
                    }
            
                    if ( (Connect-Server $XdSite.PrimaryController ) -eq "Successful" ) {
                        $Controller = $XdSite.PrimaryController 
                        $Config.Servers += $Controller
                        $XdControllers += $Controller
                        Write-Verbose "Adding XD Controller $Controller"
                    }
                    elseif ( (Connect-Server $XdSite.SecondaryController) -eq "Successful") {
                        $Controller = $XdSite.SecondaryController       
                        $Config.Servers += $Controller
                        $XdControllers += $Controller
                        Write-Verbose "Adding XD Controller $Controller"             
                    }
                    else {                    
                        Write-Verbose "Could not connect to any controllers in $XDSite"
                        $Errors += "Could not connect to any controllers in $XDSite."
                    }
                }
            }

            # ! This is more of a placeholder than anything, as we haven't implemented
            # ! RDS Checks yet. 
            if ( $Config.RdsSites ) {
                foreach ( $RdsSite in $Config.RdsSites ) {
                    # Test Connection, add the first controller that responds to Servers
                    # as well as XdControllers
                    $Controller = ""
                    if ( $null -eq $Config.Servers ) {
                        $Config | Add-Member -NotePropertyName Servers -NotePropertyValue @()
                    }
            
                    if ( (Connect-Server $RdsSite.PrimaryController ) -eq "Successful" ) {
                        $Controller = $RdsSite.PrimaryController 
                        $Config.Servers += $Controller
                        $RdsControllers += $Controller
                        Write-Verbose "Adding RDS Controller $Controller"
                    }
                    elseif ( (Connect-Server $RdsSite.SecondaryController) -eq "Successful") {
                        $Controller = $RdsSite.SecondaryController       
                        $Config.Servers += $Controller
                        $RdsControllers += $Controller
                        Write-Verbose "Adding RDS Controller $Controller"             
                    }
                    else {                    
                        Write-Verbose "Could not connect to any controllers in $RDSSite"
                        $Errors += "Could not connect to any controllers in $RDSSite."
                    }
                }
            }
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
            $ChecksUp = @()      
            $ChecksDown = @()   
            $ChecksData = @()
            $Errors = @()

            if ((Connect-Server $ComputerName) -eq "Successful") {
                Write-Verbose "Series $Series - Connection Successful to $ComputerName"

                # Ports
                foreach ($Port in $Config.Ports) { 
                    Write-Verbose "Testing $ComputerName - Port $Port"
                    if ( Test-NetConnection $ComputerName -Port $Port -InformationLevel Quiet ) {
                        Write-Verbose "Success $ComputerName - Port $Port"
                        $PortsUp += $Port   
                    }
                    else {
                        Write-Verbose "Failure $ComputerName - Port $Port"
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
                
                # Tests will return true or false, which will determine checkup or checkdown. 
                # If it cannot invoke a check, it will create an error and be placed in checkdown.
                # Each check should be able to create their own influx data using the series
                # information, so update that function as well. 

                if ( $State -eq "UP") {
                    # ! There's probably a more elegant way of doing this.  
                    foreach ($CheckList in $Config.Checks) {
                        foreach ( $Check in $CheckList.PSObject.Properties ) {
                            $CheckName = $Check.Name
                            $CheckValue = $Check.Value
                            Write-Verbose "$Computername performing $CheckName"
                            # IF the check cannot run the test successfully, it returns False.  
                            # If the check can run the test successfully, but there were problems
                            # it will populate an Errors property in the returned object.
                            $Values = @()
                                
                            # ! Should we have a check enabled?
                            switch ($CheckName) {
                                "XdDesktop" { 
                                    if ( $ComputerName -in $XdControllers ) {    
                                        $params = @{
                                            Broker         = $ComputerName;
                                            WorkerTestMode = $CheckValue.testmode;
                                            Workload       = 'desktop';
                                            BootThreshold  = $CheckValue.BootThreshold;
                                            HighLoad       = $CheckValue.HighLoad
                                        }
                                        $Values = Test-XdWorker @params
                                    }
                                }
                                "XdServer" {
                                    if ( $ComputerName -in $XdControllers ) { 
                                        $params = @{
                                            Broker         = $ComputerName;
                                            WorkerTestMode = $CheckValue.testmode;
                                            Workload       = 'server';
                                            BootThreshold  = $CheckValue.BootThreshold;
                                            HighLoad       = $CheckValue.HighLoad
                                        }
                                        $Values = Test-XdWorker @params
                                    }
                                }
                                "XdSessionInfo" {
                                    if ( ($true -eq $CheckValue) -and ($ComputerName -in $XdControllers) ) {
                                        $Values = Test-XdSessionInfo $ComputerName 
                                    }
                                }

                                # License Checks
                                "XdLicense" { 
                                    $Values = Test-XdLicense $ComputerName $CheckValue.LicenseType
                                }

                                # Site/Env Checks
                                "XdDeliveryGroupHealth" { 
                                    if ( ($true -eq $CheckValue) -and ($ComputerName -in $XdControllers) ) { 
                                        $Values = Test-XdDeliveryGroupHealth $ComputerName 
                                    }
                                    else {
                                        $Values = "SKIP CHECK"                                     
                                    }
                                }
                                "XdCatalogHealth" { 
                                    if ( ($true -eq $CheckValue) -and ($ComputerName -in $XdControllers) ) {
                                        $Values = Test-XdCatalogHealth $ComputerName
                                    }
                                    else {
                                        $Values = "SKIP CHECK"                                     
                                    }
                                }
                                "XdHypervisorHealth" { 
                                    if ( ($true -eq $CheckValue) -and ($ComputerName -in $XdControllers) ) {
                                        $Values = Test-XdHypervisorHealth $ComputerName
                                    }
                                    else {
                                        $Values = "SKIP CHECK"                                     
                                    }
                                }
                                "XdControllerHealth" { 
                                    if ( ($true -eq $CheckValue) -and ($ComputerName -in $XdControllers) ) { 
                                        $Values = Test-XdControllerHealth $ComputerName 
                                    }
                                    else {
                                        $Values = "SKIP CHECK"                                     
                                    }
                                }

                                # ! Placeholder
                                "RdsDesktop" {
                                    if ( $ComputerName -in $RdsControllers ) { }
                                }
                                "RdsServer" {
                                    if ( $ComputerName -in $RdsControllers ) { }
                                }
                                "RdsSessionInfo" {
                                    if ( $ComputerName -in $RdsControllers ) { }
                                }

                                # XenServer
                                # ! Not Tested
                                "XenServer" {
                                    $XenServerPassword = ConvertTo-SecureString $CheckValue.Password -AsPlainText -Force
                                    $Values = Test-XenServer $ComputerName $CheckValue.Username $XenServerPassword
                                }
           
                                # Netscaler Checks
                                # ! Changed to reflect JSON template
                                "Netscaler" {
                                    $NetScalerUserName = $CheckValue.username
                                    $NetScalerPasswordPlain = $CheckValue.password
                                    $NetScalerPassword = ConvertTo-SecureString $NetScalerPasswordPlain -AsPlainText -Force
                                    $Values = Test-Netscaler $ComputerName $NetScalerUserName $NetScalerPassword
                                }
                                # ! Changed to reflect JSON template
                                "NetscalerGateway" { 
                                    $NetScalerUserName = $CheckValue.username
                                    $NetScalerPasswordPlain = $CheckValue.password
                                    $NetScalerPassword = ConvertTo-SecureString $NetScalerPasswordPlain -AsPlainText -Force
                                    $Values = Test-NetscalerGateway $ComputerName $NetScalerUserName $NetScalerPassword
                                }

                                # PVS 
                                # ! Not yet fully implemented.  
                                "PVSStats" { }

                                # URL Checks
                                "HTTPUrl" { 
                                    $Url = "http://$($ComputerName):$($CheckValue.Port)$($CheckValue.Path)"
                                    Write-Verbose "Testing URL: $Url"
                                    $Values = Test-URL -Url $Url
                                 
                                }
                                "HTTPSUrl" { 
                                    $Url = "https://$($ComputerName):$($CheckValue.Port)$($CheckValue.Path)"
                                    Write-Verbose "Testing URL: $Url"
                                    $Values = Test-URL -Url $Url
                                }
                                "ValidCert" { 
                                    $Values = Test-ValidCert $ComputerName $CheckValue.Port
                                }

                                # Instead of a continue here, do nothing so that the test CheckName fails.  
                                Default { Write-Verbose "Could not find test function for $CheckName" }
                            }
           
                            # Validate Success
                            # This is true for empty and $False values  
                            if ( $false -eq $Values ) {     
                                $ChecksDown += $CheckName
                                $Errors += "$CheckName failed"
                                $State = "DEGRADED"
                            }         

                            # No need to have a check 
                            elseif ( "SKIP CHECK" -eq $Values ) {
                                Write-Verbose "Skipping $CheckName"
                            }

                            # This might be redundant. 
                            else {
                                # Gets here with a $True or an object returned. 
                                $ChecksUp += $CheckName
                                # Just because we completed the test successfully, doesn't mean it was without
                                # errors. 
                                if ("Boolean" -ne $Values.GetType().Name) {
                                    $Values | ForEach-Object {
                                        if ( $_.Errors.Count -gt 0 ) {
                                            Write-Verbose "Found Errors in $CheckName returned Values"
                                            $Errors += $_.Errors
                                            #    $State = "DEGRADED"
                                            # ! Review
                                        } 
                                        # Remove the check's errors since they've been passed to the Series.
                                        # Write-Verbose "Removing Errors from Values"
                                        # This works whether or not the property exists.  
                                        $_.PSObject.Properties.Remove('Errors')
                                             
                                        # Now that we've removed Errors, if there's still data, lets pass it on. 
                                        if ( $null -ne $_ ) {
                                            $ChecksData += [PSCustomObject]@{
                                                CheckName = $CheckName
                                                Values    = $_
                                            }
                                        }                
                                    }    
                                }      
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
                # ! Validate this is correct.  
                if ( "DEGRADED" -eq $State ) {
                    if ( (0 -eq $ServicesUp.Count) -and (0 -eq $PortsUp.Count) -and (0 -eq $ChecksUp.Count) ) {
                        Write-Verbose "$ComputerName is effectively down."
                        $Errors += "$ComputerName is effectively down."
                        $State = "DOWN"
                    } 
                }
            }
            # Server is down - not responding to ping
            # ! Anything else to be set / returned? 
            else {
                Write-Verbose "$ComputerName is down."
                $State = "DOWN"
                $PortsDown += $Config.Ports
                $ServicesDown += $Config.Services
                    
                foreach ($Check in $Config.Checks) {
                    $ChecksDown += $Check.PSObject.Properties.Name
                }
                $Errors += "$ComputerName is down." 
            }
        
            Write-Verbose "ComputerName: $ComputerName"
            Write-Verbose "State: $State"
            Write-Verbose "Ports Up: $PortsUp"
            Write-Verbose "PortsDown: $PortsDown"
            Write-Verbose "ServicesUp: $ServicesUp"
            Write-Verbose "ServicesDown: $ServicesDown"
            Write-Verbose "ChecksUp: $ChecksUp"
            Write-Verbose "ChecksDown: $ChecksDown"
            Write-Verbose "CheckData: $CheckData"
            Write-Verbose "Errors: $Errors"
            
            # ! Did you alter results?  Was there a good reason?
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
        
        # Write-Verbose "$(ConvertTo-Json -inputObject $Results)"

        return [PSCustomObject]@{
            'Series'  = $Series
            'Results' = $Results
        }
  
    }

    End { }
}