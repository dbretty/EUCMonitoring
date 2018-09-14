function New-HtmlReport {
    <#   
.SYNOPSIS   
    Generates the HTML Output Report
.DESCRIPTION 
    Generates the HTML Output Report
.PARAMETER HTMLOutputFile 
    HTML Output File
.PARAMETER HTMLOutputLocation 
    HTML Output File
.PARAMETER EUCMonitoring
    EUC Monitoring Output Object
.NOTES
    Current Version:        1.0
    Creation Date:          12/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             12/03/2018          Function Creation
    David Brett             1.1             29/03/2018          Updating function to cater for the new object
    Adam Yarborough         1.2             05/06/2018          Updated object definition modeling
    David Brett             1.3             25/06/2018          Updated report generation to support new object model
    David Brett             1.4             26/06/2018          Bug Fixes and Code Cleaning
                                                                Fixes #24
                                                                Fixes #40
    David Brett             1.5             21/08/2018          Bug fixes and naming clean 
    Alex Spicola            1.6             11/09/2018          Worker donut site name, bug fixes
.EXAMPLE
    None Required
#> 

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    
    Param
    (
        [Parameter(ValueFromPipeline)]
        [ValidateScript( { Test-Path -Type Leaf -Include '*.json' -Path $_ } )]
        [string]$JSONFile = ("$(get-location)\euc-monitoring.json"),
        [Parameter(ValueFromPipeline)]
        [ValidateScript( { Test-Path -Type Leaf -Include '*.css' -Path $_ } )]
        [string]$CSSFile = ("$(get-location)\euc-monitoring.css"),
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Results
    )

    # Generate HTML Output File
    $StartTime = (Get-Date)

    try {
        $ConfigObject = Get-Content -Raw -Path $JSONFile | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Error reading JSON.  Please Check File and try again."
    }
 
    $HTMLOutputLocation = $ConfigObject.Global.OutputLocation
    $HTMLOutputFile = $ConfigObject.Global.WebData.htmloutputfile
    $HTMLOutputFileFull = Join-Path -Path $HTMLOutputLocation -ChildPath $HTMLOutputFile

    $UpColor = $ConfigObject.Global.WebData.UpColour
    $DownColor = $ConfigObject.Global.WebData.DownColour

    # If outfile exists - delete it
    if (test-path $HTMLOutputFileFull) {
        Remove-Item $HTMLOutputFileFull
    }

    # Write HTML Header Information
    "<html>" | Out-File $HTMLOutputFileFull -Append
    "<head>" | Out-File $HTMLOutputFileFull -Append

    # Write CSS Style
    "<style>" | Out-File $HTMLOutputFileFull -Append
    $CSSData = Get-Content $CSSFile
    $CSSData | Out-File $HTMLOutputFileFull -Append
    "</style>" | Out-File $HTMLOutputFileFull -Append
    

    # Add automatic refresh in seconds. 
    $RefreshDuration = $ConfigObject.Global.WebData.RefreshDuration
    if ( $RefreshDuration -ne 0 ) {
        '<meta http-equiv="refresh" content="' + $RefreshDuration + '" >' | Out-File $HTMLOutputFileFull -Append
    }
    
    "</head>" | Out-File $HTMLOutputFileFull -Append
    "<body>" | Out-File $HTMLOutputFileFull -Append

    # Write Page Header
    $Title = $ConfigObject.Global.WebData.title
    $LogoFile = $ConfigObject.Global.WebData.logofile
    "<table border='0' width='100%'' cellspacing='0' cellpadding='0'>" | Out-File $HTMLOutputFileFull -Append
    "<tr>" | Out-File $HTMLOutputFileFull -Append
    "<td class='title-info'>" | Out-File $HTMLOutputFileFull -Append
    $title | Out-File $HTMLOutputFileFull -Append
    "</td>" | Out-File $HTMLOutputFileFull -Append
    "<td width='40%' align=right valign=top>" | Out-File $HTMLOutputFileFull -Append
    "<img src='$logofile'>" | Out-File $HTMLOutputFileFull -Append
    "</td>" | Out-File $HTMLOutputFileFull -Append
    "</tr>" | Out-File $HTMLOutputFileFull -Append
    "</table>" | Out-File $HTMLOutputFileFull -Append

    # Write Infrastructure Table Header
    "<table border='0' width='100%'' cellspacing='0' cellpadding='0'>" | Out-File $HTMLOutputFileFull -Append
    "<tr>" | Out-File $HTMLOutputFileFull -Append

    $Height = 50
    $Width = 50


    # Infrastructure Donuts
    Write-Verbose "Showing results at $timeStamp`:" 
    $InfraData = ""
    $Errors = ""

    # Figure out column percentage
    $TotalInf = 0
    foreach ($SeriesResult in $Results) {
        if ("Worker" -ne $seriesresult.series) {
            $totalinf ++
        } 
    } 
    if ($TotalInf -gt 1) {$totalinf--} else {$TotalInf = 1}
    $ColumnPercent = 100 / [int]$totalinf

    foreach ($SeriesResult in $Results) { 
        $DonutStroke = $ConfigObject.Global.WebData.InfraDonutStroke
        $Height = $ConfigObject.Global.WebData.InfraDonutSize
        $Width = $Height
        $Up = 0
        $Down = 0
        $SiteName = "" # Blank XD site name, not used for these donuts
        $Series = $SeriesResult.Series
        if ($null -ne $series) {
            if ( "Worker" -ne $Series ) {
                foreach ($Result in $SeriesResult.Results) {
                    $Up += $Result.PortsUp.Count + $Result.ServicesUp.Count + $Result.ChecksUp.Count
                    $Down += $Result.Errors.Count 
                    $Errors += "$($Result.ComputerName) - $($Result.Errors)`n"
                }
                "<td width='$ColumnPercent%' align=center valign=top>" | Out-File $HTMLOutputFileFull -Append
                switch ($Series) {
                    "Xenserver" {$NewSeries = "Citrix HV"; break}
                    "Storefront" {$NewSeries = "StoreFront"; break}
                    "XdLicensing" {$NewSeries = "Licensing"; break}
                    "XdControllers" {$NewSeries = "Controllers"; break}
                    "NetScalerGateway" {$NewSeries = "Citrix Gtwy"; break}
                    "Provisioning" {$NewSeries = "PVS"; break}
                    "NetScaler" {$NewSeries = "Citrix ADC"; break}
                    default {$NewSeries = $Series; break}
                }
                Get-DonutHTML $Height $Width $UpColor $DownColor $DonutStroke $SiteName $NewSeries $Up $Down | Out-File $HTMLOutputFileFull -Append
                "</td>" | Out-File $HTMLOutputFileFull -Append
            }
        }
    }
    "</tr>" | Out-File $HTMLOutputFileFull -Append
    "</table>" | Out-File $HTMLOutputFileFull -Append

    # Worker Object Heights, this is for reference. 
    "<table border='0' width='100%'' cellspacing='0' cellpadding='0'>" | Out-File $HTMLOutputFileFull -Append
    "<tr>" | Out-File $HTMLOutputFileFull -Append

    $TotalWorkers = 0
    if ($true -eq $ConfigObject.Worker.Checks.XdDesktop) { $TotalWorkers++ }
    if ($true -eq $ConfigObject.Worker.Checks.XdServer) { $TotalWorkers++ }

    if (2 -eq $TotalWorkers) {
        $ColumnPercent = 35
    }
    else {
        $ColumnPercent = 50
    }
    # Worker Donuts
    $WorkerData = ""

    foreach ($SeriesResult in $Results) { 
        $DonutStroke = $ConfigObject.Global.WebData.WorkerDonutStroke
        $Height = $ConfigObject.Global.WebData.WorkerDonutSize
        $ShowSiteName = $ConfigObject.Global.WebData.WorkerSiteName
        $Width = $Height
        $Series = $SeriesResult.Series

        if ( "Worker" -eq $Series ) {

            foreach ($Result in $SeriesResult.Results) {
                foreach ( $CheckData in $Result.ChecksData ) {
                    $CheckDataName = $CheckData.CheckName
                    $Up = $CheckData.Values.BrokerMachineRegistered
                    $Down = $CheckData.Values.BrokerMachineUnRegistered
                    if ($CheckDataName -ne "XdSessionInfo") {
                        switch ($CheckDataName) {
                            "XdServer" {$NewName = "Server Workloads"; break}
                            "XdDesktop" {$NewName = "Desktop Workloads"; break}
                            default {$NewName = $Series; break}
                        }
                        "<td width='$ColumnPercent%' align=center valign=top>" | Out-File $HTMLOutputFileFull -Append
                        if ($ShowSiteName -eq $true) {
                            $SiteName = $CheckData.Values.SiteName | Select-Object -Unique
                            Get-DonutHTML $Height $Width $UpColor $DownColor $DonutStroke $SiteName $NewName $Up $Down -Worker | Out-File $HTMLOutputFileFull -Append
                        } else {
                            $SiteName = ""
                            Get-DonutHTML $Height $Width $UpColor $DownColor $DonutStroke $SiteName $NewName $Up $Down -Worker | Out-File $HTMLOutputFileFull -Append
                        }
                        "</td>" | Out-File $HTMLOutputFileFull -Append
                    }
                }
            }
        }
    }

    #Infrastructure and Error Data
    "<td width='$ColumnPercent%' align=left valign=top>" | Out-File $HTMLOutputFileFull -Append
    "</br>" | Out-File $HTMLOutputFileFull -Append

    # Licensing Data
    if ($true -eq $ConfigObject.XdLicensing.test) { 
        "<div class='info-title'>" | Out-File $HTMLOutputFileFull -Append
        "Current Licensing Status" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append
        foreach ($SeriesResult in $Results) { 
            $Series = $SeriesResult.Series
            if ( "XdLicensing" -eq $Series ) {
                $ChecksDetail = $SeriesResult.Results.checksdata
                "<div class='info-text'>" | Out-File $HTMLOutputFileFull -Append
                foreach ($CheckDetails in $ChecksDetail) {
                    $Available = $CheckDetails.values.TotalAvailable
                    $Issued = $CheckDetails.values.TotalIssued
                    $LicType = $CheckDetails.values.LicenseType
                    "License - $LicType - $Available/$Issued<br>" | Out-File $HTMLOutputFileFull -Append
                }
                "</div>" | Out-File $HTMLOutputFileFull -Append
                "<br>" | Out-File $HTMLOutputFileFull -Append
            }
        }
    }

    # Server Workload Data
    if ($true -eq $ConfigObject.Worker.Checks.XdServer) { 
        "<div class='info-title'>" | Out-File $HTMLOutputFileFull -Append
        "Server Workload Data" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append
        foreach ($SeriesResult in $Results) { 
            $Series = $SeriesResult.Series
            if ( "Worker" -eq $Series ) {
                $ChecksDetail = $SeriesResult.Results.checksdata
                foreach ($CheckDetails in $ChecksDetail) {
                    if ("XdServer" -eq $CheckDetails.Checkname) {
                        "<div class='info-text'>" | Out-File $HTMLOutputFileFull -Append
                        $Up = $CheckDetails.values.ConnectedUsers
                        $Down = $CheckDetails.values.DisconnectedUsers
                        "Total User Base - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append
                        $Up = $CheckDetails.values.DeliveryGroupsNotInMaintenance
                        $Down = $CheckDetails.Values.DeliveryGroupsInMaintenance
                        "Delivery Group Maintenance Mode - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append
                        $Up = $CheckDetails.Values.BrokerMachineOn
                        $Down = $CheckDetails.values.BrokerMachineOff
                        "Broker Machine Power State - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append
                        $Up = $CheckDetails.values.BrokerMachineRegistered
                        $Down = $CheckDetails.values.BrokerMachineUnRegistered
                        "Broker Machine Registration - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append
                        $Up = $CheckDetails.values.BrokerMachineRegistered
                        $Down = $CheckDetails.values.BrokerMachineInMaintenance
                        "Broker Machine Maintenance Mode - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append
                        "</div>" | Out-File $HTMLOutputFileFull -Append
                        "<br>" | Out-File $HTMLOutputFileFull -Append
                    }
                }
            }
        }
    }
   
    # Desktop Workload Data
    if ($true -eq $ConfigObject.Worker.Checks.XdDesktop) { 
        "<div class='info-title'>" | Out-File $HTMLOutputFileFull -Append
        "Desktop Workload Data" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append
        foreach ($SeriesResult in $Results) { 
            $Series = $SeriesResult.Series
            if ( "Worker" -eq $Series ) {
                $ChecksDetail = $SeriesResult.Results.checksdata
                foreach ($CheckDetails in $ChecksDetail) {
                    if ("XdDesktop" -eq $CheckDetails.Checkname) {
                        "<div class='info-text'>" | Out-File $HTMLOutputFileFull -Append
                        $Up = $CheckDetails.values.ConnectedUsers
                        $Down = $CheckDetails.values.DisconnectedUsers
                        "Total User Base - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append
                        $Up = $CheckDetails.values.DeliveryGroupsNotInMaintenance
                        $Down = $CheckDetails.Values.DeliveryGroupsInMaintenance
                        "Delivery Group Maintenance Mode - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append
                        $Up = $CheckDetails.Values.BrokerMachineOn
                        $Down = $CheckDetails.values.BrokerMachineOff
                        "Broker Machine Power State - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append
                        $Up = $CheckDetails.values.BrokerMachineRegistered
                        $Down = $CheckDetails.values.BrokerMachineUnRegistered
                        "Broker Machine Registration - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append
                        $Up = $CheckDetails.values.BrokerMachineRegistered
                        $Down = $CheckDetails.values.BrokerMachineInMaintenance
                        "Broker Machine Maintenance Mode - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append
                        "</div>" | Out-File $HTMLOutputFileFull -Append
                        "<br>" | Out-File $HTMLOutputFileFull -Append
                    }
                }
            }
        }
    }

    # Gateway Details
    if ($true -eq $ConfigObject.NetScalerGateway.test) {
        # Title
        "<div class='info-title'>" | Out-File $HTMLOutputFileFull -Append
        "Citrix Networking" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append

        $ICAUsers = 0
        $VPNUsers = 0
        $TotalUsers = 0

        foreach ($SeriesResult in $Results) { 
            $Series = $SeriesResult.Series
            if ( "NetScalerGateway" -eq $Series ) {
                $ChecksDetail = $SeriesResult.Results.checksdata
                foreach ($CheckDetails in $ChecksDetail) {
                    $ICAUsers = $ICAUsers + $CheckDetails.values.ICAUsers
                    $VPNUsers = $VPNUsers + $CheckDetails.values.VPNUsers
                    $TotalUsers = $TotalUsers + $CheckDetails.values.TotalGatewayUsers
                }
            }
        }
        "<div class='info-text'>" | Out-File $HTMLOutputFileFull -Append
        "ICA Users - $ICAUsers<br>"  | Out-File $HTMLOutputFileFull -Append
        "VPN Users - $VPNUsers<br>"  | Out-File $HTMLOutputFileFull -Append
        "Total Users - $TotalUsers<br>"  | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append
        "<br>" | Out-File $HTMLOutputFileFull -Append
    }

    # Output Monitoring Data - Infrastructure Errors
    $InfraData = join-path -path $HTMLOutputLocation -ChildPath "infra-errors.txt"

    if (test-path $InfraData) {
        "<div class='error-title'>" | Out-File $HTMLOutputFileFull -Append
        "Current Infrastructure Errors" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append
        $InfraInfo = Get-Content $InfraData
        "<div class='error-text'>" | Out-File $HTMLOutputFileFull -Append
        foreach ($Line in $InfraInfo) {
            "$Line<br>"  | Out-File $HTMLOutputFileFull -Append
        }
        "</div>" | Out-File $HTMLOutputFileFull -Append
        Remove-Item $InfraData
        # Insert a line break
        "<br>" | Out-File $HTMLOutputFileFull -Append
    }

    # Output Monitoring Data - Infrastructure Errors
    $WorkerData = join-path -path $HTMLOutputLocation -ChildPath "worker-errors.txt"

    if (test-path $WorkerData) {
        "<div class='error-title'>" | Out-File $HTMLOutputFileFull -Append
        "Current XenDesktop Worker Errors" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append
        $WorkerInfo = Get-Content $WorkerData
        "<div class='error-text'>" | Out-File $HTMLOutputFileFull -Append
        foreach ($Line in $WorkerInfo) {
            "$Line<br>"  | Out-File $HTMLOutputFileFull -Append
        }
        "</div>" | Out-File $HTMLOutputFileFull -Append
        Remove-Item $WorkerData
        # Insert a line break
        "<br>" | Out-File $HTMLOutputFileFull -Append
    }

    "</td>" | Out-File $HTMLOutputFileFull -Append
    "</tr>" | Out-File $HTMLOutputFileFull -Append
    "</table>" | Out-File $HTMLOutputFileFull -Append

    # Last Run Details
    "<table>" | Out-File $HTMLOutputFileFull -Append
    "<tr>" | Out-File $HTMLOutputFileFull -Append
    "<div class='info-text'>" | Out-File $HTMLOutputFileFull -Append
    $LastRun = Get-Date
    "Last Run Date: $LastRun" | Out-File $HTMLOutputFileFull -Append
    "</div>" | Out-File $HTMLOutputFileFull -Append
    "</tr>" | Out-File $HTMLOutputFileFull -Append

    # Write the Worker Table Footer
    "</table>" | Out-File $HTMLOutputFileFull -Append
    
    # Write HTML Footer Information
    "</body>" | Out-File $HTMLOutputFileFull -Append
    "</html>" | Out-File $HTMLOutputFileFull -Append

    $EndTime = (Get-Date)
    Write-Verbose "New-HtmlReport finished."
    Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalMinutes) Minutes"
    Write-Verbose "Elapsed Time: $(($EndTime-$StartTime).TotalSeconds) Seconds"
}
