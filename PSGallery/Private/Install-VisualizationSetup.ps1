function Install-VisualizationSetup {
    <#
    .SYNOPSIS
        Sets up the EUC Monitoring Platform Influx / Grafana platform
    .DESCRIPTION
        Sets up the EUC Monitoring Platform Influx / Grafana platform.  Requires internet connection to Github.
    .PARAMETER MonitoringPath
        Determines the
    .PARAMETER QuickConfig
        Interactive JSON file creation based on default values
    .INPUTS
        None
    .OUTPUTS
        None
    .NOTES
        Current Version:        1.1
        Creation Date:          19/03/2018
    .CHANGE CONTROL
        Name                    Version         Date                Change Detail
        Hal Lange               1.0             16/04/2018          Initial Creation of Installer
        Adam Yarborough         1.1             11/07/2018          Integration of Hal's work and updating.
    .PARAMETER MonitoringPath
        Folder path to download files needed for monitoring process
    .EXAMPLE
        None Required

    #>


    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)][string]$MonitoringPath = (get-location).Path,
        [parameter(Mandatory = $false, ValueFromPipeline = $true)][string]$GrafanaVersion = "https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-5.2.1.windows-amd64.zip",
        [parameter(Mandatory = $false, ValueFromPipeline = $true)][string]$InfluxVersion = "https://dl.influxdata.com/influxdb/releases/influxdb-1.5.3_windows_amd64.zip",
        [parameter(Mandatory = $false, ValueFromPipeline = $true)][string]$NSSMVersion = "https://nssm.cc/release/nssm-2.24.zip"
    )

    begin {
        [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
        If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Throw "You must be administrator in order to execute this script"
        }

    }

    process {
        #Base Directory for Install
        Write-Output "Install location set to $MonitoringPath"
        # Get the dashboard config.
        if ( test-path $MonitoringPath ) {
            Write-Verbose "$MonitoringPath directory already Present"
        }
        else {
            New-Item $MonitoringPath -ItemType Directory
            Write-Verbose "EUC Monitoring Directory Created $Monitoring"
        }

        # EUCMonitoring Specific
        $DashboardConfig = "$MonitoringPath\DashboardConfig"
        $dashDatasource = "$DashboardConfig\DataSource.json"
        $dashboards = @("EUCMonitoring.json",
            "AD-Details.json",
            "App-V-Details.json",
            "CC-Details.json",
            "Director-Details.json",
            "FAS-Details.json",
            "Netscaler-Details.json",
            "NetscalerGateway-Details.json",
            "PVS-Details.json",
            "SQL-Details.json",
            "Storefront-Details.json",
            "UPS-Details.json",
            "WEM-Details.json",
            "XDController-Details.json",
            "XDLicensing-Details.json"
        )

        # Get the dashboard config.
        if ( test-path $DashboardConfig ) {
            Write-Verbose "DashboardConfig directory already Present"
        }
        else {
            New-Item $DashboardConfig -ItemType Directory
            Write-Verbose "EUC Monitoring Dashboard Directory Created $DashboardConfig"
        }
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dbretty/EUCMonitoring/v2_beta/DashboardConfig/DataSource.json" -OutFile $dashDatasource

        #Get the current dashboards
        if ( test-path "$DashboardConfig\Dashboards" ) {
            Write-Verbose "Dashboards directory already Present"
        }
        else {
            New-Item "$DashboardConfig\Dashboards" -ItemType Directory
            Write-Verbose "EUC Monitoring Dashboard Directory Created $DashboardConfig\Dashboards"
        }
        foreach ($board in $Dashboards) {
            Write-Verbose "Getting Dashboard: $board"
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dbretty/EUCMonitoring/v2_beta/DashboardConfig/Dashboards/$board" -OutFile "$DashboardConfig\Dashboards\$board"
        }

        #open FW for Grafana
        Write-Output "Opening Firewall Rules for Grafana and InfluxDB"

        $Catch = New-NetFirewallRule -DisplayName "Grafana Server" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow -Description "Allow Grafana Server"
        $Catch = New-NetFirewallRule -DisplayName "InfluxDB Server" -Direction Inbound -LocalPort 8086 -Protocol TCP -Action Allow -Description "Allow InfluxDB Server" -AsJob

        function GetAndInstall ( $Product, $DownloadFile, $Dest ) {
            $DownloadLocation = (Get-Item Env:Temp).value  #Use the Temp folder as Temp Download location
            $zipFile = "$DownloadLocation\$Product.zip"
            Write-Output "Downloading $Product to $zipfile"
            if ( ($DownloadFile -match "http://") -or ($DownloadFile -match "https://") ) {
                $Catch = Invoke-WebRequest $DownloadFile -outFile $zipFile
            }
            else {
                Copy-Item $DownloadFile -Destination "$DownloadLocation\$Product.zip"
            }

            Write-Output "Installing $Product to $Dest"
            # Expand-Archive -LiteralPath "$DownloadLocation\$Product.zip"
            $shell = New-Object -ComObject shell.application
            $zip = $shell.NameSpace($ZipFile)
            foreach ( $item in $zip.items() ) {
                $shell.Namespace($Dest).CopyHere($item)
            }
            $Catch = ""
            Write-Output $Catch
        }



        #Install Grafana
        GetAndInstall "Grafana" $GrafanaVersion $MonitoringPath
        $Grafana = (get-childitem $MonitoringPath | Where-Object {$_.Name -match 'graf'}).FullName

        #Install InfluxDB
        GetAndInstall "InfluxDB" $InfluxVersion $MonitoringPath
        $Influx = (get-childitem $MonitoringPath | Where-Object {$_.Name -match 'infl'}).FullName
        # When taking in a user supplied path, need to change, this will make sure there's a appended '/'
        # then strip away drive letter and change backslashs to forward( '\' to '/' ), and get rid of any 
        # double slashes.  Then we'll updated the influxdb.conf.
        $IDataPath = "$MonitoringPath/".replace((resolve-path $MonitoringPath).Drive.Root, '').replace("\", "/").Replace("//", "/")
        $content = [System.IO.File]::ReadAllText("$Influx\influxdb.conf").Replace("/var/lib/influxdb", "/$($IDataPath)InfluxData/var/lib/influxdb")
        [System.IO.File]::WriteAllText("$Influx\influxdb.conf", $content)
        [Environment]::SetEnvironmentVariable("Home", $Influx, "Machine")

        #Install NSSM
        GetAndInstall "NSSM" $NSSMVersion $MonitoringPath
        #Setup Services
        $NSSM = (get-childitem $MonitoringPath | Where-Object {$_.Name -match 'nssm'}).FullName
        $NSSMEXE = "$nssm\win64\nssm.exe"
        & $nssmexe Install "Grafana Server" $Grafana\bin\grafana-server.exe
        # & $nssmexe Set "Grafana Server" DisplayName "Grafana Server"
        & $nssmexe Install "InfluxDB Server" $Influx\influxd.exe -config influxdb.conf
        # & $nssmexe Set "InfluxDB Server" DisplayName "InfluxDB Server"
        Write-Output "Starting Services"
        start-service "Grafana Server"
        start-service "InfluxDB Server"
        & $Influx\influx.exe -execute 'Create Database EUCMonitoring'

        # need to import eventually grafana pages.
        Push-Location $grafana\bin
        & .\Grafana-cli.exe plugins install btplc-status-dot-panel
        & .\Grafana-cli.exe plugins install vonage-status-panel
        & .\Grafana-cli.exe plugins install briangann-datatable-panel
        & .\Grafana-cli.exe plugins install grafana-piechart-panel
        Write-Output "Restarting Grafana Server"
        stop-service "Grafana Server"
        start-service "Grafana Server"

        Write-Output "Setting up Grafana..."
        start-sleep 5

        # Setup Grafana
        $pair = "admin:admin"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [System.Convert]::ToBase64String($bytes)
        $basicAuthValue = "Basic $base64"
        $headers = @{ Authorization = $basicAuthValue }

        Write-Output "Setting up Grafana Datasource"
        $datasourceURI = "http://localhost:3000/api/datasources"
        $inFile = $dashDatasource
        $Catch = Invoke-WebRequest -Uri $datasourceURI -Method Post -infile $infile -Headers $headers -ContentType "application/json"

        Write-Output "Setting up Grafana Dashboards"
        Write-Output "Using $DashboardConfig\Dashboards" -ForegroundColor Magenta
        $dashs = get-childitem "$DashboardConfig\Dashboards"
        $dashboardURI = "http://localhost:3000/api/dashboards/import"
        foreach ( $dashboard in $dashs ) {
            $inFile = $dashboard.fullname
            $Catch = Invoke-WebRequest -Uri $dashboardURI -Method Post -infile $infile -Headers $headers -ContentType "application/json"
        }

        $Catch = Invoke-WebRequest -URI "http://localhost:3000/api/search?query=EUCMonitoring" -outfile .\home.json -header $headers
        $GrafanaConfig = Get-Content -Raw -Path .\home.json | ConvertFrom-Json
        $SiteID = $GrafanaConfig.id
        $GrafanaConfig = "{""theme"": """",""homeDashboardId"":$SiteID,""timezone"":""browser""}"
        Remove-Item .\home.json

        Write-Output "Setting up Grafana Homepage"
        $Catch = Invoke-WebRequest -URI "http://localhost:3000/api/org/preferences" -method PUT -body $GrafanaConfig -header $headers -ContentType "application/json"

        # This is to avoid the assigned and never used checks.
        Pop-Location

        # Purely to pass variable checks
        $Catch = ""
        Write-Verbose $Catch

        Write-Verbose "Downloading helper script."
        # Download the helper script
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dbretty/EUCMonitoring/v2_beta/DashboardConfig/Begin-EUCMonitor.ps1" -OutFile "$MonitoringPath\Begin-EUCMonitor.ps1"

        Write-Output "NOTE: Grafana and Influx are now installed as services.  You might need to set their startup type to"
        Write-Output "automatic if you plan on using this long term.`n"

        Write-Output "Please edit the json config template, setting the Influx enabled to true amongst your other changes"
        Write-Output "and save as euc-monitoring.json.`n"
        #& "C:\Windows\System32\notepad.exe" $MonitoringPath\euc-monitoring.json

        Write-Output "After configuring, run Begin-EUCMonitoring under appropriate privs.  Each refresh cycle"
        Write-Output "it will upload to local influxdb as a single timestamp. You might want to invoke it like:"
        Write-Output "> $MonitoringPath\Begin-EUCMonitor.ps1 -MonitoringPath $MonitoringPath"
        Write-Output " - or - "
        Write-Output "> Set-Location $MonitoringPath; .\Begin-EUCMonitor.ps1"
    }

    end {
    }
}