function Test-XenDesktop {
    <#   
.SYNOPSIS   
    Tests XenDesktop Workers
.DESCRIPTION 
    Tests XenDesktop Workers
.PARAMETER GlobalObj
    Object with Global Citrix settings
.PARAMETER WorkerObj
    Object with workload settings
.NOTES
    Name                    Version         Date                Change Detail
    Ryan Butler             1.1             29/03/2018          Converted to function
.EXAMPLE
    None Required
#> 
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$GlobalObj,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$WorkerObj

    )
    #Variables
    $XDBrokerPrimary = $GlobalObj.xdbrokerprimary
    $xdbrokerfailover = $GlobalObj.xdbrokerfailover
    $WorkerTestMode = $WorkerObj.mode
    $WorkLoads = $WorkerObj.workloads
    $ServerBootThreshold = $WorkerObj.serverbootthreshold
    $ServerHighLoad = $WorkerObj.serverhighload
    $DesktopBootThreshold = $WorkerObj.desktopbootthreshold
    $DesktopHighLoad = $WorkerObj.desktophighload

    #Create PS object
    $results = [PSCustomObject]@{}

    # Display the XenDesktop Brokers Passed In
    Write-Verbose "XenDesktop Primary Broker $XDBrokerPrimary"
    Write-Verbose "XenDesktop Failover Broker $XDBrokerFailover"

    # Test the primary broker for connectivity and set global broker vairable is good, if not fail over to the secondary
    if ((Connect-Server $XDBrokerPrimary) -eq "Successful") {
        $Broker = $XDBrokerPrimary
    }
    else {
        if ((Connect-Server $XDBrokerFailover) -eq "Successful") {
            $Broker = $XDBrokerFailover
        }
        else {
            Write-Verbose "Cannot connect to any of the configured brokers - quitting"
            Write-error "Cannot Connect to XenDesktop Brokers $XDBrokerPrimary or $XDBrokerFailover"
            $Broker = "no_broker_present"
            Return # Fix Termination of Powershell instance https://git.io/vxEGW
        }
    }
    Write-Verbose "Configured XenDesktop Broker for Connectivity: $Broker"
      
    # Start Worker Monitoring Checks
    Write-Verbose "Starting Citrix Platform Worker Testing"
    # Load the Citrix Broker Powershell SDK
    $ctxsnap = add-pssnapin citrix* -ErrorAction SilentlyContinue
    $ctxsnap = get-pssnapin citrix* -ErrorAction SilentlyContinue

    if ($null -eq $ctxsnap) {
        Write-error "XenDesktop Powershell Snapin Load Failed - No XenDesktop Brokering SDK Found"
        Write-error "Cannot Load XenDesktop Powershell SDK"
        Return # Fix Termination of Powershell instance https://git.io/vxEGW
    }
    else {
        Write-Verbose "XenDesktop Powershell SDK Snapin Loaded"
    }

    Foreach ($Workload in $Workloads) {
        $WorkerList += $Workload
        if ($Workload -eq "server") {
            $ErrorFileFullPath = $ServerErrorFileFullPath
        }
        else {
            $ErrorFileFullPath = $DesktopErrorFileFullPath
        }
        # Test the XenServer Infrastructure
        $results | Add-Member -Name "$Workload" -Value (Test-Worker -Broker $Broker -WorkerTestMode $WorkerTestMode -WorkLoad $Workload -ServerBootThreshold $ServerBootThreshold -ServerHighLoad $ServerHighLoad -DesktopBootThreshold $DesktopBootThreshold -DesktopHighLoad $DesktopHighLoad -ErrorFile $ErrorFileFullPath) -MemberType "NoteProperty"
    }
    $results | Add-Member -Name "WorkerList" -Value $workerlist -MemberType "NoteProperty"
    return $results
}