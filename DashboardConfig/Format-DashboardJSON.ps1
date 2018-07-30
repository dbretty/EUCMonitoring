# Helper file to take Grafana dashboard export and prepare it for scripted import. 
# 
# Don't forget to update Install-VisualizationSetup 
<#
.SYNOPSIS
A small helper script to take Grafana dashboard export and prepare it for scripted import. 

.DESCRIPTION
A small helper script to take Grafana dashboard export and prepare it for scripted import. 
Don't forget to update Install-VisualizationSetup with the filename. 

.PARAMETER inFile
Path to your EUCMonitoring JSON config file.

.PARAMETER outFile
Path to your EUCMonitoring CSS file.

.EXAMPLE
.\Format-DashboardJSON.ps1 -inFile Dashboards\test.json -outFile Dashboards\whatever.json

.NOTES
    Current Version:        1.0
    Creation Date:          30/07/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough         1.0             30/07/2018          Initial Creation

#>
param (
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]$inFile, 
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]$outFile
) 

$Prepend = '{ "dashboard": '
$Append = ', "folderID": 0, "inputs": [ {"name": "DS_EUCMONITORING","type": "datasource","pluginId": "influxdb","value": "EUCMonitoring" } ] }'

$Content = Get-Content $inFile

# Doing it this way to confirm valid JSON.  
$Prepend + $Content + $Append | ConvertFrom-Json | ConvertTo-Json | Out-File $outFile
