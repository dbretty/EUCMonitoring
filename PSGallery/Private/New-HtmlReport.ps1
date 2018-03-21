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
.PARAMETER InfrastructureComponents 
    Number of Infrastructure Components 
.PARAMETER InfrastructureList 
    List of Infrastructure Components
.PARAMETER WorkerList 
    List of Worker Components
.NOTES
    Current Version:        1.0
    Creation Date:          12/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             12/03/2018          Function Creation
.EXAMPLE
    None Required
#> 

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$HTMLOutputFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$HTMLOutputLocation,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$InfrastructureComponents,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$InfrastructureList,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$WorkerList,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$CSSFile
    )

    # Generate HTML Output File
    $HTMLOutputFileFull = Join-Path -Path $HTMLOutputLocation -ChildPath $HTMLOutputFile

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

    "</head>" | Out-File $HTMLOutputFileFull -Append
    "<body>" | Out-File $HTMLOutputFileFull -Append

    # Write Page Header
    "<table border='0' width='100%'' cellspacing='0' cellpadding='0'>" | Out-File $HTMLOutputFileFull -Append
    "<tr>" | Out-File $HTMLOutputFileFull -Append
    "<td class='title-info'>" | Out-File $HTMLOutputFileFull -Append
    "Citrix XenDesktop Platform Monitoring" | Out-File $HTMLOutputFileFull -Append
    "</td>" | Out-File $HTMLOutputFileFull -Append
    "<td width='40%' align=right valign=top>" | Out-File $HTMLOutputFileFull -Append
    "<img src='logo.png'>" | Out-File $HTMLOutputFileFull -Append
    "</td>" | Out-File $HTMLOutputFileFull -Append
    "</tr>" | Out-File $HTMLOutputFileFull -Append
    "</table>" | Out-File $HTMLOutputFileFull -Append

    # Write Infrastructure Table Header
    "<table border='0' width='100%'' cellspacing='0' cellpadding='0'>" | Out-File $HTMLOutputFileFull -Append
    "<tr>" | Out-File $HTMLOutputFileFull -Append

    # Work out the column width for Infrastructure
    $ColumnPercent = 100 / [int]$InfrastructureComponents
    #$InfrastructureList = $InfrastructureList.Split(",")
    foreach ($InfService in $InfrastructureList) {
        Write-Verbose "Getting Donut Data for $InfService"

        # Define Table Cell Start
        "<td width='$ColumnPercent%' align=center valign=top>" | Out-File $HTMLOutputFileFull -Append

        # Get HTML Code From Monitoring Output
        $InfFile = "$InfService.html"
        $InfraInputFile = Join-Path -Path $HTMLOutputLocation -ChildPath $InfFile 
        Write-Verbose "Using Contents from $InfraInputFile"

        # Read in HTML Data
        $InfData = Get-Content $InfraInputFile

        # Write HTML Donut Data to Master File
        $InfData | Out-File $HTMLOutputFileFull -Append

        # Define Table Cell Close
        "</td>" | Out-File $HTMLOutputFileFull -Append

        Remove-Item $InfraInputFile -Force
    }
    
    # Write the Infrastructure Table Footer
    "</tr>" | Out-File $HTMLOutputFileFull -Append
    "</table>" | Out-File $HTMLOutputFileFull -Append

    # Insert a line break
    "<br>" | Out-File $HTMLOutputFileFull -Append

    # Start the Worker Donur Build
    $WorkerList = $WorkerList.Split(",")
    $WorkerCount = ($WorkerList | Measure-Object).Count

    # Work out column sizes
    if ($WorkerCount -eq 2) {
        $WorkerSize = "35%"
        $ErrorSize = "30%"  
    }
    else {
        $WorkerSize = "70%"
        $ErrorSize = "30%" 
    }

    # Write Worker Table Header
    "<table border='0' width='100%'' cellspacing='0' cellpadding='0'>" | Out-File $HTMLOutputFileFull -Append
    "<tr>" | Out-File $HTMLOutputFileFull -Append
  
    foreach ($Worker in $WorkerList) {
        Write-Verbose "Getting Donut Data for $Worker"

        # Define Table Cell Start
        "<td width='$WorkerSize' align=center valign=top>" | Out-File $HTMLOutputFileFull -Append

        # Get HTML Code From Monitoring Output
        $WrkFile = "$Worker-donut.html"
        $WorkerInputFile = Join-Path -Path $HTMLOutputLocation -ChildPath $WrkFile 
        Write-Verbose "Using Contents from $WorkerInputFile"

        # Read in HTML Data
        $WrkData = Get-Content $WorkerInputFile

        # Write HTML Donut Data to Master File
        $WrkData | Out-File $HTMLOutputFileFull -Append

        # Define Table Cell Close
        "</td>" | Out-File $HTMLOutputFileFull -Append

        Remove-Item $WorkerInputFile -Force
    }

    # Define Error Pane
    "<td class='monitoring-info'>" | Out-File $HTMLOutputFileFull -Append
    
    # Output Monitoring Data - Server
    $ServerData = Join-Path -Path $HTMLOutputLocation -ChildPath "server-htmldata.txt"

    if (test-path $ServerData) {
        "<div class='info-title'>" | Out-File $HTMLOutputFileFull -Append
        "Server Workload Data" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append
        $ServerInfo = Get-Content $ServerData
        "<div class='info-text'>" | Out-File $HTMLOutputFileFull -Append
        foreach ($Line in $ServerInfo) {
            $LineData = $Line -Split ","
            $Title = $LineData[0] 
            $Up = $LineData[1] 
            $Down = $LineData[2] 
            $LineData = $Line.Split(",")
            "$Title - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append
        }
        "</div>" | Out-File $HTMLOutputFileFull -Append
        Remove-Item $ServerData
        # Insert a line break
        "<br>" | Out-File $HTMLOutputFileFull -Append
    }
    
    # Output Monitoring Data - Desktop
    $DesktopData = Join-Path -Path $HTMLOutputLocation -ChildPath "desktop-htmldata.txt"

    if (test-path $DesktopData) {
        "<div class='info-title'>" | Out-File $HTMLOutputFileFull -Append
        "Desktop Workload Data" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append
        $DesktopInfo = Get-Content $DesktopData
        "<div class='info-text'>" | Out-File $HTMLOutputFileFull -Append
        foreach ($Line in $DesktopInfo) {
            $LineData = $Line -Split ","
            $Title = $LineData[0] 
            $Up = $LineData[1] 
            $Down = $LineData[2] 
            $LineData = $Line.Split(",")
            "$Title - $Up/$Down<br>" | Out-File $HTMLOutputFileFull -Append
        }
        "</div>" | Out-File $HTMLOutputFileFull -Append
        Remove-Item $DesktopData
        # Insert a line break
        "<br>" | Out-File $HTMLOutputFileFull -Append
    }

    # Output Monitoring Data - NetScaler Gateway Data
    $GatewayData = Join-Path -Path $HTMLOutputLocation -ChildPath "netscaler-gateway-data.txt"

    if (test-path $GatewayData) {
        "<div class='info-title'>" | Out-File $HTMLOutputFileFull -Append
        "Remote Access Data" | Out-File $HTMLOutputFileFull -Append
        "</div>" | Out-File $HTMLOutputFileFull -Append
        $GatewayInfo = Get-Content $GatewayData
        "<div class='info-text'>" | Out-File $HTMLOutputFileFull -Append
        foreach ($Line in $GatewayInfo) {
            "$Line<br>"  | Out-File $HTMLOutputFileFull -Append
        }
        "</div>" | Out-File $HTMLOutputFileFull -Append
        Remove-Item $GatewayData
        # Insert a line break
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
