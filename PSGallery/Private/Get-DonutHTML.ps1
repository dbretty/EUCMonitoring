function Get-DonutHTML {
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
    Adam Yarborough         1.1             12/06/2018          Change to return string
.EXAMPLE
    None Required
#>

    [CmdletBinding()]
    
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DonutHeight,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DonutWidth,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DonutGoodColour,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DonutBadColour,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DonutStroke,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$SeriesName,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$SeriesUpCount,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$SeriesDownCount,
        [parameter(ValueFromPipeline = $false)][switch]$Worker
    )
    
    # Sort out up and down count
    if (0 -eq $SeriesDownCount) {
        $SeriesUpCount = 100
    } else {
        $full = $SeriesUpCount + $SeriesDownCount
        $Single = 100 / $Full
        $SeriesUpCount = $Single * $SeriesUpCount
        $SeriesDownCount = $Single * $SeriesDownCount
    }

    $HTML = "<svg width='$DonutWidth' height='$DonutHeight' viewBox='0 0 42 42' class='donut'>" 
    $HTML += "<circle class='donut-hole' cx='21' cy='21' r='15.91549430918954' fill='#fff'></circle>"
    $HTML += "<circle class='donut-ring' cx='21' cy='21' r='15.91549430918954' fill='transparent' stroke='$DonutGoodColour' stroke-width='$DonutStroke'></circle>" 
    $HTML += "<circle class='donut-segment' cx='21' cy='21' r='15.91549430918954' fill='transparent' stroke='$DonutBadColour' stroke-width='$DonutStroke' stroke-dasharray='$SeriesUpCount $SeriesDownCount' stroke-dashoffset='25'></circle>" 
        
    if ( $Worker ) {
        $HTML += "<g class='worker-chart-text'>" 
        $HTML += "<text x='50%' y='50%' class='worker-chart-label'>" 
    }
    else {
        $HTML += "<g class='chart-text'>" 
        $HTML += "<text x='50%' y='50%' class='chart-label'>"      
    }
        
    $HTML += "$SeriesName" 
    $HTML += "</text>"
    $HTML += "</g>"
    $HTML += "</svg>" 

    $HTML
}
