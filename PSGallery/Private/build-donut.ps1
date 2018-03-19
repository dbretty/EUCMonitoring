function Build-Donut {
    <#   
.SYNOPSIS   
    Build a HTML Output Monitoring Page
.DESCRIPTION 
    Takes the output from the monitoring checks and pulls together a html monitoring page
.PARAMETER DonutFile 
    HTML Data Output File
.PARAMETER HTMLInput 
    HTML Input File
.PARAMETER DonutHeight 
    Donut Height
.PARAMETER DonutWidth 
    Donut Width
.PARAMETER DonutGood
    Donut Height
.PARAMETER DonutBad
    Donut Width
.PARAMETER DonutStroke
    Donut Width
.PARAMETER ServiceName
    Donut Service Name
.NOTES
    Current Version:        1.0
    Creation Date:          07/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             07/02/2018          Function Creation

.EXAMPLE
    None Required
#>

    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DonutFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DonutFullPath,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DonutHeight,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DonutWidth,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DonutGood,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DonutBad,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DonutStroke,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ServiceName
    )
    
    Write-Verbose "Creating Donut File"

    #Remove Old HTML File
    Write-Verbose "Deleting $DonutFile File"
    If (Test-Path $DonutFile) {
        Remove-Item $DonutFile
    }

    # Write Chart Data to HTML
    $HTMLInputData = Get-Content $DonutFullPath
    foreach ($Line in $HTMLInputData) {
        $LineData = $Line -Split ","
        $ChartTitle = $LineData[0]
        [int]$Good = $LineData[1]
        [int]$Bad = $LineData[2]
        $Full = $Good + $Bad
        If ($full -eq 0) {
            $Chartgood = 100
            $ChartBad = 0
        }
        else {
            $Single = 100 / $Full
            $ChartGood = $Single * $Good
            $ChartBad = $Single * $Bad
        }

        "<svg width='$DonutWidth' height='$DonutHeight' viewBox='0 0 42 42' class='donut'>" | Out-File $DonutFile -Append
        # "<svg width='100%' height='100%' viewBox='0 0 42 42' class='donut'>" | Out-File $DonutFile -Append
        "<circle class='donut-hole' cx='21' cy='21' r='15.91549430918954' fill='#fff'></circle>" | Out-File $DonutFile -Append
        "<circle class='donut-ring' cx='21' cy='21' r='15.91549430918954' fill='transparent' stroke='$DonutGood' stroke-width='$DonutStroke'></circle>" | Out-File $DonutFile -Append
        "<circle class='donut-segment' cx='21' cy='21' r='15.91549430918954' fill='transparent' stroke='$DonutBad' stroke-width='$DonutStroke' stroke-dasharray='$ChartGood $ChartBad' stroke-dashoffset='25'></circle>" | Out-File $DonutFile -Append
        if ($ServiceName -match "Server") {
            "<g class='worker-chart-text'>" | Out-File $DonutFile -Append
            "<text x='50%' y='50%' class='worker-chart-label'>" | Out-File $DonutFile -Append
        }
        else {
            if ($ServiceName -match "Desktop") {   
                "<g class='worker-chart-text'>" | Out-File $DonutFile -Append
                "<text x='50%' y='50%' class='worker-chart-label'>" | Out-File $DonutFile -Append 
            }
            else {
                "<g class='chart-text'>" | Out-File $DonutFile -Append
                "<text x='50%' y='50%' class='chart-label'>" | Out-File $DonutFile -Append
            }     
        }
        
        "$ServiceName" | Out-File $DonutFile -Append
        "</text>" | Out-File $DonutFile -Append
        "</g>" | Out-File $DonutFile -Append
        "</svg>" | Out-File $DonutFile -Append
    }
}
