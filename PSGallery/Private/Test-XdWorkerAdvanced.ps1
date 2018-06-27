function Test-XdWorkerAdvanced {
    <#   
.SYNOPSIS   
    Checks the Status of the XenDesktop Workers Passed In On each Server or Desktop Individually
.DESCRIPTION 
    Checks the Status of the XenDesktop Workers Passed In On each Server or Desktop Individually
.PARAMETER Machines 
    XenDesktop Machines to use for the checks
.PARAMETER BootThreshold 
    Server Boot Threshold
.PARAMETER HighLoad 
    Server High Load
.NOTES
    Current Version:        1.0
    Creation Date:          27/06/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             27/06/2018          Function Creation
.EXAMPLE
    None Required
#>

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Machines,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$BootThreshold,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$HighLoad
    )

    Begin { 
        $pool = [RunspaceFactory]::CreateRunspacePool(1, [int]$env:NUMBER_OF_PROCESSORS + 1)
        $pool.ApartmentState = "MTA"
        $pool.Open()
        $runspaces = @()
    }
    
    Process {

        $scriptblock = {
            Param (
                [string]$Machine,
                [string]$BootThreshold,
                [string]$HighLoad
            )

            Add-PSSnapin Citrix.Broker.* -ErrorAction SilentlyContinue

            $Errors = @()
            $Status = "Not Run"

            # Test for Uptime of Machine
            [regex]$rx = "\d\.\d$"
            $data = test-wsman $Machine
            $rx.match($data.ProductVersion)
            if ($rx.match($data.ProductVersion).value -eq '3.0') {
                $os = Get-Ciminstance -ClassName win32_operatingsystem -ComputerName $Machine -ErrorAction Continue
            }
            else {
                $opt = New-CimSessionOption -Protocol Dcom
                $session = new-cimsession -ComputerName $machine -SessionOption $opt
                $os = $session | Get-Ciminstance -ClassName win32_operatingsystem
            }
            $Uptime = $OS.LocalDateTime - $os.LastBootUpTime
            $UptimeDays = $Uptime.Days

            If ($UptimeDays -lt [int]$BootThreshold) {
                Add-PSSnapin Citrix.Broker.* -ErrorAction SilentlyContinue
                $Load = Get-BrokerMachine -HostedMachineName $Machine -Property LoadIndex
                $CurrentLoad = $Load.LoadIndex
                If ($CurrentLoad -lt $HighLoad) {
                    $Status = "Passed"
                }
                else {
                    $Status = "Degraded"
                    $errors += "$Machine has a high load of $CurrentLoad"
                }
            }
            else {
                $Status = "Degraded"
                $errors += "$Machine has not been booted in $UptimeDays days"
            }

            return [PSCustomObject]@{
                'Server'   = $Machine
                'Services' = $Status
                'Errors'   = $Errors
            }
        }

        $Results = @()

        foreach ( $Machine in $Machines) {

            $MachineName = $Machine.HostedMachineName
            $runspace = [PowerShell]::Create()
            $null = $runspace.AddScript($scriptblock)
            $null = $runspace.AddArgument($MachineName)
            $null = $runspace.AddArgument($BootThreshold)
            $null = $runspace.AddArgument($HighLoad)
            $runspace.RunspacePool = $pool
            $runspaces += [PSCustomObject]@{ Pipe = $runspace; Status = $runspace.BeginInvoke() }
        }

        while ($runspaces.Status.IsCompleted -notcontains $true) {}

        foreach ($runspace in $runspaces ) {
            $results += $runspace.Pipe.EndInvoke($runspace.Status)
            $runspace.Pipe.Dispose()
        }
    
        $pool.Close() 
        $pool.Dispose()

        Remove-Variable runspaces -Force

        return $results
    }

    End { }
}