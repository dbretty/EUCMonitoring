Function Get-ICALatency {
    Param (
        $ComputerName
    )

    $Last = get-Counter "\\$computername\ICA Session(*)\Latency - Session Average"
    $Avg = get-Counter "\\$computername\ICA Session(*)\Latency - Last Recorded"
    
    return $Last, $Avg
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