          
          
function Start-TestEngine {
    <#
.SYNOPSIS
    Starts the main engine behind EUCMonitoring
.DESCRIPTION
    Starts the main engine behind EUCMonitoring
.PARAMETER JSONConfigFilename
    The path to the JSON config file.  
.NOTES
    Current Version:        1.0
    Creation Date:          07/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             07/02/2018          Function Creation

.EXAMPLE
    None Required
#>
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ConfigObject,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Results
    ) 
    $timestamp = Get-InfluxTime(get-date)
    $InfluxURI = Get-InfluxURI $ConfigObject
         
    foreach ($result in $Results) {

        # XXX CHANGEME XXX 
        #$Series = "TEMPLATE"
        #This assumes influx doesn't care about the order as long as they're grouped
        # Ports Up
        $PortString = ""
        foreach ( $Port in $PortsUp ) {
            if ( $PortString -eq "" ) { $PortString = "Port$Port=1" } 
            else { $PortString += ",Port$Port=1" }
        }
        foreach ( $Port in $PortsDown ) {
            if ( $PortString -eq "" ) { $PortString = "Port$Port=0" } 
            else { $PortString += ",Port$Port=0" }
        }

        if ( "" -ne $PortString ) {
            $PortString = $PortString -replace " ", "\ "
            $PostParams = "$Series-Ports,Server=$($Result.ComputerName) $PortString $timeStamp"
            Invoke-RestMethod -Method "POST" -Uri $InfluxUri -Body $postParams
        }
        # This assumes influx doesn't care about the order as long as they're grouped.
        # 1 Means Up, 0 means Down.  
        # Services Up
        $ServiceString = ""
        foreach ( $Service in $ServicesUp ) {
            if ( $ServiceString -eq "" ) { $ServiceString = "$Service=1" } 
            else { $ServiceString += ",$Service=1" }
        }
        foreach ( $Service in $ServicesDown ) {
            if ( $ServiceString -eq "" ) { $ServiceString = "$Service=0" } 
            else { $ServiceString += ",$Service=0" }
        }

        if ( "" -ne $ServiceString ) {
            $ServiceString = $ServiceString -replace " ", "\ "
            $PostParams = "$Series-Services,Server=$($Result.ComputerName) $ServiceString $timeStamp"
            Invoke-RestMethod -Method "POST" -Uri $InfluxUri -Body $postParams
        }    
        #This assumes influx doesn't care about the order as long as they're grouped
        # Checks Up

        $CheckString = ""
        foreach ( $Check in $ChecksUp ) {
            if ( $CheckString -eq "" ) { $CheckString = "$Check=1" } 
            else { $CheckString += ",$Check=1" }
        }
        foreach ( $Service in $ChecksDown ) {
            if ( $CheckString -eq "" ) { $CheckString = "$Check=0" } 
            else { $CheckString += ",$Check=0" }
        }

        $CheckString = $ServiceString -replace " ", "\ "
        $PostParams = "$Series-Checks,Server=$($Result.ComputerName) $ServiceString $timeStamp"
        Invoke-RestMethod -Method "POST" -Uri $InfluxUri -Body $postParams
    }
}