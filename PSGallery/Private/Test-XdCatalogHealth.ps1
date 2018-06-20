function Test-XdCatalogHealth {
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
    Adam Yarborough         1.1             07/06/2018          Update for object model.
.EXAMPLE
    None Required
#>


    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$AdminAddress
    )

    Begin {
        $ctxsnap = Add-PSSnapin Citrix.EnvTest.* -ErrorAction SilentlyContinue
        $ctxsnap = Get-PSSnapin Citrix.EnvTest.* -ErrorAction SilentlyContinue

        if ($null -eq $ctxsnap) {
            Write-Error "XenDesktop Powershell Snapin Load Failed"
            Write-Error "Cannot Load Citrix.EnvTest.* Powershell SDK"
            Return $false
        }
        else {
            Write-Verbose "XenDesktop Powershell SDK Snapin Loaded"
        }
    }
    
    Process { 
        #Create array with results
        $Results = @()
        $Errors = @()

        Write-Verbose "Initialize Test Variables"
        $Health = $true
 
        Write-Verbose "Catalog Env Check started"
        $XDCatalogs = Get-BrokerCatalog -AdminAddress $AdminAddress 

        foreach ( $Catalog in $XDCatalogs ) {
            Write-Verbose "Initialize Test Variables"
            Write-Verbose "Testing $($Catalog.Name)"
            $TestTarget = New-EnvTestDiscoveryTargetDefinition -AdminAddress $AdminAddress -TargetIdType "Catalog" -TestSuiteId "Catalog" -TargetId $Catalog.Uuid
            $TestResults = Start-EnvTestTask -AdminAddress $AdminAddress -InputObject $TestTarget -RunAsynchronously
            foreach ( $Result in $TestResults.TestResults ) {
                foreach ( $Component in $Result.TestComponents ) {
                    Write-Verbose "$Catalog.Name - $($Component.TestID) - $($Component.TestComponentStatus)"
                    if ( ($Component.TestComponentStatus -ne "CompletePassed") -and ($Component.TestComponentStatus -ne "NotRun") ) {
                        $Errors += "$Catalog.Name - $($Component.TestID) - $($Component.TestComponentStatus)" 
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

    End { }
}