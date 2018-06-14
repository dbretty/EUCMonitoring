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
    #$HTMLOutputFileFull = Join-Path -Path $HTMLOutputLocation -ChildPath $HTMLOutputFile
    $StartTime = (Get-Date)

    try {
        $ConfigObject = Get-Content -Raw -Path $JSONFile | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Error reading JSON.  Please Check File and try again."
    }
 
    $HTMLOutputLocation = $ConfigObject.Global.WebData.OutputLocation
    $HTMLOutputFile = $ConfigObject.Global.WebData.htmloutputfile
    $HTMLOutputFileFull = Join-Path -Path $ConfigObject.Global.WebData.OutputLocation -ChildPath $HTMLOutputFile

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
    "<table border='0' width='100%'' cellspacing='0' cellpadding='0'>" | Out-File $HTMLOutputFileFull -Append
    "<tr>" | Out-File $HTMLOutputFileFull -Append
    "<td class='title-info'>" | Out-File $HTMLOutputFileFull -Append
    "EUC Monitoring" | Out-File $HTMLOutputFileFull -Append
    "</td>" | Out-File $HTMLOutputFileFull -Append
    "<td width='40%' align=right valign=top>" | Out-File $HTMLOutputFileFull -Append
    "<img src='logo.png'>" | Out-File $HTMLOutputFileFull -Append
    "</td>" | Out-File $HTMLOutputFileFull -Append
    "</tr>" | Out-File $HTMLOutputFileFull -Append
    "</table>" | Out-File $HTMLOutputFileFull -Append

    # Write Infrastructure Table Header
    "<table border='0' width='100%'' cellspacing='0' cellpadding='0'>" | Out-File $HTMLOutputFileFull -Append
    "<tr>" | Out-File $HTMLOutputFileFull -Append


    # Infrastructure Donuts
    Write-Verbose "Showing results at $timeStamp`:" 
    $InfraData = ""
    foreach ($SeriesResult in $Results) { 

        $Up = 0
        $Down = 0

        $Series = $SeriesResult.Series
        # Write-Host "--- Series: $Series ---" -ForegroundColor "Cyan"
        if ( "Worker" -ne $Series ) {
            foreach ($Result in $SeriesResult.Results) {
                "<td width='$ColumnPercent%' align=center valign=top>" | Out-File $HTMLOutputFileFull -Append
                New-DonutHTML  | Out-File $HTMLOutputFileFull -Append

            }
        }
    }

    # Worker Donuts
    foreach ($SeriesResult in $Results) { 

        $Series = $SeriesResult.Series
        Write-Host "--- Series: $Series ---" -ForegroundColor "Cyan"
        if ( "Worker" -eq $Series ) {
            foreach ($Result in $SeriesResult.Results) {
                New-DonutHTML  -Worker | Out-File $HTMLOutputFileFull -Append
            }
        }
    }
    # Work out the column width for Infrastructure
    #$ColumnPercent = 100 / [int]($EUCMonitoring.infrastructurelist).count
    #foreach ($InfService in $InfrastructureList) {
    #    Write-Verbose "Getting Donut Data for $InfService"

    # Define Table Cell Start
    #"<td width='$ColumnPercent%' align=center valign=top>" | Out-File $HTMLOutputFileFull -Append

    # Get HTML Code From Monitoring Output
    #$InfFile = "$InfService.html"
    #$InfraInputFile = Join-Path -Path $HTMLOutputLocation -ChildPath $InfFile 
    #Write-Verbose "Using Contents from $InfraInputFile"

    # Read in HTML Data
    #$InfData = Get-Content $InfraInputFile

    # Write HTML Donut Data to Master File
    #$InfData | Out-File $HTMLOutputFileFull -Append

    # Define Table Cell Close
    #"</td>" | Out-File $HTMLOutputFileFull -Append

    #Remove-Item $InfraInputFile -Force
    #}
    
    # Write the Infrastructure Table Footer
    "</tr>" | Out-File $HTMLOutputFileFull -Append
    "</table>" | Out-File $HTMLOutputFileFull -Append

    # Insert a line break
    "<br>" | Out-File $HTMLOutputFileFull -Append

    # Start the Worker Donur Build
    #$WorkerCount = ($WorkerList | Measure-Object).Count

    # Work out column sizes
    #if ($WorkerCount -eq 2) {
    #    $WorkerSize = "35%"
    #    $ErrorSize = "30%"  
    #}
    #else {
    #    $WorkerSize = "70%"
    #    $ErrorSize = "30%" 
    #}

    # Write Worker Table Header
    "<table border='0' width='100%'' cellspacing='0' cellpadding='0'>" | Out-File $HTMLOutputFileFull -Append
    "<tr>" | Out-File $HTMLOutputFileFull -Append
  
    #  foreach ($Worker in $WorkerList) {
    #       Write-Verbose "Getting Donut Data for $Worker"
    #
    #      # Define Table Cell Start
    #       "<td width='$WorkerSize' align=center valign=top>" | Out-File $HTMLOutputFileFull -Append
    #
    #    # Get HTML Code From Monitoring Output
    #     $WrkFile = "$Worker-donut.html"
    #      $WorkerInputFile = Join-Path -Path $HTMLOutputLocation -ChildPath $WrkFile 
    #       Write-Verbose "Using Contents from $WorkerInputFile"
    #
    #      # Read in HTML Data
    #       $WrkData = Get-Content $WorkerInputFile
    #
    #      # Write HTML Donut Data to Master File
    #       $WrkData | Out-File $HTMLOutputFileFull -Append
    #
    #      # Define Table Cell Close
    #       "</td>" | Out-File $HTMLOutputFileFull -Append
    #
    #     Remove-Item $WorkerInputFile -Force
    # }

    # Define Error Pane
    "<td class='monitoring-info'>" | Out-File $HTMLOutputFileFull -Append
    
    # Output Monitoring Data - Server
    if (!$null -eq $EUCMonitoring.server) {
        # Title    
        "<div class='info-title'>" | Out-File $HTMLOutputFileFull -Append
        "Server Workload Data" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append

        # Detail
        "<div class='info-text'>" | Out-File $HTMLOutputFileFull -Append

        # Total User Base
        $Up = $EUCMonitoring.server.TotalConnectedUsers
        $Down = $EUCMonitoring.server.TotalUsersDisconnected
        "Total User Base - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append

        # Delivery Group Maintenance Mode
        $Up = $EUCMonitoring.server.DeliveryGroupsInMaintenance
        $Down = $EUCMonitoring.server.DeliveryGroupsNotInMaintenance
        "Delivery Group Maintenance Mode - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append

        # Broker Machine Power State
        $Up = $EUCMonitoring.server.BrokerMachineOn
        $Down = $EUCMonitoring.server.BrokerMachineOff
        "Broker Machine Power State - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append

        # Broker Machine Registration
        $Up = $EUCMonitoring.server.BrokerMachineRegistered
        $Down = $EUCMonitoring.server.BrokerMachineUnRegistered
        "Broker Machine Registration - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append

        # Broker Machine Maintenance Mode
        $Up = $EUCMonitoring.server.BrokerMachineRegistered
        $Down = $EUCMonitoring.server.BrokerMachineInMaintenance
        "Broker Machine Maintenance Mode - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append

        # Close Section
        "</div>" | Out-File $HTMLOutputFileFull -Append
        "<br>" | Out-File $HTMLOutputFileFull -Append
    }

    
    # Output Monitoring Data - Desktop
    if (!$null -eq $EUCMonitoring.desktop) {
        # Title    
        "<div class='info-title'>" | Out-File $HTMLOutputFileFull -Append
        "Desktop Workload Data" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append

        # Detail
        "<div class='info-text'>" | Out-File $HTMLOutputFileFull -Append

        # Total User Base
        $Up = $EUCMonitoring.desktop.TotalConnectedUsers
        $Down = $EUCMonitoring.desktop.TotalUsersDisconnected
        "Total User Base - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append

        # Delivery Group Maintenance Mode
        $Up = $EUCMonitoring.desktop.DeliveryGroupsInMaintenance
        $Down = $EUCMonitoring.desktop.DeliveryGroupsNotInMaintenance
        "Delivery Group Maintenance Mode - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append

        # Broker Machine Power State
        $Up = $EUCMonitoring.desktop.BrokerMachineOn
        $Down = $EUCMonitoring.desktop.BrokerMachineOff
        "Broker Machine Power State - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append

        # Broker Machine Registration
        $Up = $EUCMonitoring.desktop.BrokerMachineRegistered
        $Down = $EUCMonitoring.desktop.BrokerMachineUnRegistered
        "Broker Machine Registration - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append

        # Broker Machine Maintenance Mode
        $Up = $EUCMonitoring.desktop.BrokerMachineRegistered
        $Down = $EUCMonitoring.desktop.BrokerMachineInMaintenance
        "Broker Machine Maintenance Mode - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append

        # Close Section
        "</div>" | Out-File $HTMLOutputFileFull -Append
        "<br>" | Out-File $HTMLOutputFileFull -Append
    }

    # Output Monitoring Data - NetScaler Gateway
    if (!$null -eq $EUCMonitoring.NetScalerGateway) {
        # Title
        "<div class='info-title'>" | Out-File $HTMLOutputFileFull -Append
        "Remote Access Data" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append

        $ICAUsers = $EUCMonitoring.NetScalerGateway.ICAUsers
        $VPNUsers = $EUCMonitoring.NetScalerGateway.VPNUsers
        $TotalUsers = $ICAUsers + $VPNUsers

        "<div class='info-text'>" | Out-File $HTMLOutputFileFull -Append
        "ICA Users - $ICAUsers<br>"  | Out-File $HTMLOutputFileFull -Append
        "VPN Users - $VPNUsers<br>"  | Out-File $HTMLOutputFileFull -Append
        "Total Users - $TotalUsers<br>"  | Out-File $HTMLOutputFileFull -Append

        # Close Section
        "</div>" | Out-File $HTMLOutputFileFull -Append
        "<br>" | Out-File $HTMLOutputFileFull -Append
    }

    # Output Monitoring Data - Infrastructure Errors
    $InfraData = Join-Path -Path $HTMLOutputLocation -ChildPath "infra-errors.txt"

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

    # Output Monitoring Data - Worker Errors - Server
    $ServerData = Join-Path -Path $HTMLOutputLocation -ChildPath "server-errors.txt"

    if (test-path $ServerData) {
        "<div class='error-title'>" | Out-File $HTMLOutputFileFull -Append
        "Current Server Workload Errors" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append
        $ServerInfo = Get-Content $ServerData
        "<div class='error-text'>" | Out-File $HTMLOutputFileFull -Append
        foreach ($Line in $ServerInfo) {
            "$Line<br>"  | Out-File $HTMLOutputFileFull -Append
        }
        "</div>" | Out-File $HTMLOutputFileFull -Append
        Remove-Item $ServerData
        # Insert a line break
        "<br>" | Out-File $HTMLOutputFileFull -Append
    }

    # Output Monitoring Data - Worker Errors - Desktop
    $DesktopData = Join-Path -Path $HTMLOutputLocation -ChildPath "desktop-errors.txt"

    if (test-path $DesktopData) {
        "<div class='error-title'>" | Out-File $HTMLOutputFileFull -Append
        "Current Desktop Workload Errors" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append
        $DesktopInfo = Get-Content $DesktopData
        "<div class='error-text'>" | Out-File $HTMLOutputFileFull -Append
        foreach ($Line in $DesktopInfo) {
            "$Line<br>"  | Out-File $HTMLOutputFileFull -Append
        }
        "</div>" | Out-File $HTMLOutputFileFull -Append
        Remove-Item $DesktopData
        # Insert a line break
        "<br>" | Out-File $HTMLOutputFileFull -Append
    }
  
    "<div class='info-text'>" | Out-File $HTMLOutputFileFull -Append
    $LastRun = Get-Date
    "Last Run Date: $LastRun" | Out-File $HTMLOutputFileFull -Append
    "</div>" | Out-File $HTMLOutputFileFull -Append

    "</td>" | Out-File $HTMLOutputFileFull -Append

    # Write the Worker Table Footer
    "</tr>" | Out-File $HTMLOutputFileFull -Append
    "</table>" | Out-File $HTMLOutputFileFull -Append
    
    # Write HTML Footer Information
    "</body>" | Out-File $HTMLOutputFileFull -Append
    "</html>" | Out-File $HTMLOutputFileFull -Append


}
