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
    Adam Yarborough         1.1             10/08/2018          Added GUI simply for ease of copy/paste.

#>
param (
    [parameter(Mandatory = $false, ValueFromPipeline = $true)]$inFile = "", 
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]$outFile
) 

$Prepend = '{ "dashboard": '
$Append = ', "folderID": 0, "inputs": [ {"name": "DS_EUCMONITORING","type": "datasource","pluginId": "influxdb","value": "EUCMonitoring" } ] }'

if ("" -eq $inFile) { 
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
     
    # Create the Label.
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Size(10, 10) 
    $label.Size = New-Object System.Drawing.Size(280, 20)
    $label.AutoSize = $true
    $label.Text = "Paste the JSON here."

    # Create the TextBox used to capture the user's text.
    $textBox = New-Object System.Windows.Forms.TextBox 
    $textBox.Location = New-Object System.Drawing.Size(10, 40) 
    $textBox.Size = New-Object System.Drawing.Size(575, 200)
    $textBox.AcceptsReturn = $true
    $textBox.AcceptsTab = $false
    $textBox.Multiline = $true
    $textBox.ScrollBars = 'Both'
    $textBox.Text = "In Grafana.`nGo to Share -> Export -> View JSON -> Copy to Clipboard`nPaste the contents here."

    # Create the OK button.
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Size(415, 250)
    $okButton.Size = New-Object System.Drawing.Size(75, 25)
    $okButton.Text = "OK"
    $okButton.Add_Click( { $form.Tag = $textBox.Text; $form.Close() })

    # Create the Cancel button.
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Size(510, 250)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 25)
    $cancelButton.Text = "Cancel"
    $cancelButton.Add_Click( { $form.Tag = $null; $form.Close() })

    # Create the form.
    $form = New-Object System.Windows.Forms.Form 
    $form.Text = "Format-DashboardJSON Dialog"
    $form.Size = New-Object System.Drawing.Size(610, 320)
    $form.FormBorderStyle = 'FixedSingle'
    $form.StartPosition = "CenterScreen"
    $form.AutoSizeMode = 'GrowAndShrink'
    $form.Topmost = $True
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    $form.ShowInTaskbar = $true

    # Add all of the controls to the form.
    $form.Controls.Add($label)
    $form.Controls.Add($textBox)
    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)

    # Initialize and show the form.
    $form.Add_Shown( {$form.Activate()})
    $form.ShowDialog() > $null   # Trash the text of the button that was clicked.

    $Content = $form.Tag
}
else {
    $Content = Get-Content $inFile
}
# Doing it this way to confirm valid JSON.  
$Prepend + $Content + $Append | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Out-File $outFile
