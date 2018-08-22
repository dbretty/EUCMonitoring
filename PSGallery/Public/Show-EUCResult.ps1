Function Show-EUCResult {
    <#
.SYNOPSIS
    Console based output
    
.DESCRIPTION
    Console Based output
.PARAMETER Results
    The path to the JSON config file.  
.NOTES
    Current Version:        1.0
    Creation Date:          07/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough            1.0          17/05/2018          Function Creation

.EXAMPLE
    None Required
#>
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Results
    ) 

    # We want all results to represent the same moment in time, even if that's not true for 
    # collation reasons. This is why this step happens at the end. 
    $timeStamp = (get-date)
         

    Write-Verbose "Showing results at $timeStamp`:" 
    foreach ($SeriesResult in $Results) { 

        $Series = $SeriesResult.Series
        Write-Host "--- Series: $Series ---" -ForegroundColor "Cyan"

        foreach ($Result in $SeriesResult.Results) {

            # XXX CHANGEME XXX 
            #$Series = "TEMPLATE"
            #This assumes influx doesn't care about the order as long as they're grouped
            # Ports Up
            if ("UP" -eq $Result.State ) { $hostColor = "Green" }
            elseif ( "DEGRADED" -eq $Result.State) { $hostColor = "Yellow" }
            else { $hostColor = "red"}
            Write-Host "Server:   " -NoNewline
            Write-Host "$($Result.ComputerName)" -ForegroundColor $hostColor

            if ( ($Result.PortsUp.Count -gt 0) -or ($Result.PortsDown.Count -gt 0) ) {
                Write-Host "Ports:    " -NoNewline
                foreach ( $Port in $Result.PortsUp ) {
                    Write-Host "$Port " -ForegroundColor "Green" -NoNewline
                }
                foreach ( $Port in $Result.PortsDown ) {
                    Write-Host "$Port " -ForegroundColor "Red" -NoNewline
                }
                Write-Host ""
            }
 
            # This assumes influx doesn't care about the order as long as they're grouped.
            # 1 Means Up, 0 means Down.  
            # Services Up
            if ( ($Result.ServicesUp.Count -gt 0 ) -or ($Result.ServicesDown.Count -gt 0) ) {
                Write-Host "Services: " -NoNewline
                foreach ( $Service in $Result.ServicesUp ) {
                    Write-Host "$Service " -ForegroundColor "Green" -NoNewline
                }
                foreach ( $Service in $Result.ServicesDown ) {
                    Write-Host "$Service " -ForegroundColor "Red" -NoNewline
                }
                Write-Host ""
            }

            #This assumes influx doesn't care about the order as long as they're grouped
            # Checks Up

            if ( ($Result.ChecksUp.Count -gt 0) -or ($Result.ChecksDown.Count -gt 0) ) {
                Write-Host "Checks:   " -NoNewline
                foreach ( $Check in $Result.ChecksUp ) {
                    Write-Host "$Check " -ForegroundColor "Green" -NoNewline
                }
                foreach ( $Check in $Result.ChecksDown ) {
                    Write-Host "$Check " -ForegroundColor "Red" -NoNewline
                }
                Write-Host ""
            }

            # Unique Numerical Data will follow
            # ValueName=NumericalValue
            # Write-Verbose "$(ConvertTo-JSON -inputObject $Result.ChecksData -Depth 6)"
            foreach ( $CheckData in $Result.ChecksData ) {
                $ParamString = ""
                
                $CheckDataName = $CheckData.CheckName
                $CheckData.Values.PSObject.Properties | ForEach-Object {
                    if ( $ParamString -eq "" ) { $ParamString = "$($_.Name)=$($_.Value)" } 
                    else { $ParamString += ", $($_.Name)=$($_.Value)" }
                }
                
                if ( "" -ne $ParamString ) {
                    $PostParams = "$CheckDataName`: $ParamString"
                    #             Write-Verbose $PostParams
                    Write-Host $PostParams
                }
            }

            <# Decided not to make this part of Show-EUCResult, as things are mostly color coded.
                Subject to change, as this is mostly for testing anyways.  
            foreach ( $Err in $Result.Errors ) {
                Write-Host "$Err " -ForegroundColor "Red" -NoNewline
            } 
            Write-Host "`n"
            #>
        }
        Write-Host "`n"
    }
}
