Function Get-Uptime {
    <#   
.SYNOPSIS   
    Gets the uptime for a server passed in
.DESCRIPTION 
    Gets the uptime for a server passed in
.PARAMETER ComputerName 
    The Server to check the uptime
.NOTES
    Current Version:        1.0
    Creation Date:          19/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             19/02/2018          Function Creation

.EXAMPLE
    None Required
#>

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ComputerName
    )

    begin {}

    process {
        try {
            $hostdns = [System.Net.DNS]::GetHostEntry($ComputerName)
            $OS = Get-WmiObject win32_operatingsystem -ComputerName $ComputerName -ErrorAction Stop
            $BootTime = $OS.ConvertToDateTime($OS.LastBootUpTime)
            $Uptime = $OS.ConvertToDateTime($OS.LocalDateTime) - $boottime
            return $Uptime.Days
        } 
        catch [Exception] {
            Write-Output "$computer $($_.Exception.Message)"
        }
    }

    end {}
}
