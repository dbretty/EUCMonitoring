 
function Test-XdControllerHealth {
    <#   
.SYNOPSIS   
    Checks the Status of the Environmental Tests Passed In
.DESCRIPTION 
    Checks the Status of the Environmental Tests Passed In
.PARAMETER AdminAddress
    Current Broker
.NOTES
    Current Version:        1.0
    Creation Date:          22/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough         1.0             21/03/2018          Function Creation
    Adam Yarborough         1.1             07/06/2018          Function update to new object model

.EXAMPLE
    None Required
#>

    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$AdminAddress
    )

    #Create array with results
    $Results = @()
    $Errors = @()
    $Health = $true
 
    Write-Verbose "Delivery Controllers Env Check started"
    $XDDeliveryControllers = Get-BrokerController -AdminAddress $AdminAddress

    Write-Verbose "Variables and Arrays Initialized"

    foreach ( $DeliveryController in $XDDeliveryControllers) {
        Write-Verbose "Initialize Test Variables"
        Write-Verbose "Testing $($DeliveryController.MachineName)"
        $TestTarget = New-EnvTestDiscoveryTargetDefinition -AdminAddress $AdminAddress -TargetIdType "Infrastructure" -TestSuiteId "Infrastructure" -TargetId $DeliveryController.Uuid
        $TestResults = Start-EnvTestTask -AdminAddress $AdminAddress -InputObject $TestTarget -RunAsynchronously
        foreach ( $Result in $TestResults.TestResults ) {
            foreach ( $Component in $Result.TestComponents ) {
                Write-Verbose "$($DeliveryController.MachineName) - $($Component.TestID) - $($Component.TestComponentStatus)"
                if ( ($Component.TestComponentStatus -ne "CompletePassed") -and ($Component.TestComponentStatus -ne "NotRun") ) {
                    $Errors += "$($DeliveryController.MachineName) - $($Component.TestID) - $($Component.TestComponentStatus)" 
                    $Health = $false 
                }
            } 
        }
    }
    if ( $Health ) {
        return $true
    }
    else {
        $Results += [PSCustomObject]@{
            'Errors' = $Errors
        }
        return $Results
    }
}

