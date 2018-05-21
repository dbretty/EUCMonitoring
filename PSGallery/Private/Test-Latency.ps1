Function Get-ICASessionLatency {
    Param (
        $ComputerName
    )

    # $Avg = get-Counter "\\$computername\ICA Session(*)\Latency - Session Average"
    $Last = get-Counter "\\$computername\ICA Session(*)\Latency - Last Recorded"
    
    #return $Last, $Avg

    return $Last.CounterSamples.CookedValue | Measure-Object -Average -Maximum -Minimum | Select-Object Average, Maximum, Sum
}

<#

$C = get-counter "\\xa7a01\ICA Session(*)\Latency - Session Average"
$C.CounterSamples
$C.CounterSamples.CookedValue
$C.CounterSamples.CookedValue | measure -Average
$C = get-counter "\\xa7a01\ICA Session(*)\Latency - Last Recorded"
$C.CounterSamples.CookedValue | measure -Average
$C.CounterSamples.CookedValue
$C.CounterSamples.CookedValue | measure -Average -Maximum -Minimum

#>