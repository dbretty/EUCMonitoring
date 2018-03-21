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
            # Commenting out as the variable is never used
            # $hostdns = [System.Net.DNS]::GetHostEntry($ComputerName)
            $os = Get-Ciminstance -ClassName win32_operatingsystem -ComputerName $ComputerName -ErrorAction Stop
            # Commenting out as was using the WMI method and not CIM
            # $OS = Get-WmiObject win32_operatingsystem -ComputerName $ComputerName -ErrorAction Stop
            # $BootTime = $OS.ConvertToDateTime($OS.LastBootUpTime)
            # $Uptime = $OS.ConvertToDateTime($OS.LocalDateTime) - $boottime
            $Uptime = $OS.LocalDateTime - $os.LastBootUpTime
            return $Uptime.Days
        } 
        catch [Exception] {
            Write-Output "$computer $($_.Exception.Message)"
        }
    }

    end {}
}
