function Test-EnvChecksXD {
    <#   
.SYNOPSIS   
    Checks the Status of the Environmental Tests Passed In
.DESCRIPTION 
    Checks the Status of the Environmental Tests Passed In
.PARAMETER Broker
    Current Broker
.PARAMETER ErrorFile 
    Infrastructure Error File to Log To
.PARAMETER OutputFile 
    Infrastructure OutputFile
.PARAMETER DDCcheck 
    "yes" test Delivery Controllers Environmental Checks. All other inputs to skip.
.PARAMETER DeliveryGroupCheck
    "yes" to test Delivery Groups Environmental Checks. All others to skip. 
.PARAMETER CatalogCheck
    "yes" to test Catalogs Environmental Checks. All others to skip.
.PARAMETER HypervisorCheck
    "yes" to test Hypervisor and Associated Resources Environmental Checks. All other inputs to skip.
.NOTES
    Current Version:        1.0
    Creation Date:          22/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough         1.0             21/03/2018          Function Creation

.EXAMPLE
    None Required
#>
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$AdminAddress,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$OutputFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DDCcheck,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DeliveryGroupCheck,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$CatalogCheck,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$HypervisorCheck
    )

    if ($DDCcheck -eq "yes") {
        Write-Verbose "Delivery Controllers Env Check started"
        $EnvCheckUp = 0
        $EnvCheckDown = 0
        $XDDeliveryControllers = Get-BrokerController -AdminAddress $AdminAddress

        Write-Verbose "Variables and Arrays Initialized"

        foreach ( $DeliveryController in $XDDeliveryControllers) {
            $Status = "Passed"
            Write-Verbose "Initialize Test Variables"
            Write-Verbose "Testing $($DeliveryController.MachineName)"
            $TestTarget = New-EnvTestDiscoveryTargetDefinition -AdminAddress $AdminAddress -TargetIdType "Infrastructure" -TestSuiteId "Infrastructure" -TargetId $DeliveryController.Uuid
            $TestResults = Start-EnvTestTask -AdminAddress $AdminAddress -InputObject $TestTarget -RunAsynchronously
            foreach ( $Result in $TestResults.TestResults ) {
                foreach ( $Component in $Result.TestComponents ) {
                    Write-Verbose "$($DeliveryController.MachineName) - $($Component.TestID) - $($Component.TestComponentStatus)"
                    if ( ($Component.TestComponentStatus -ne "CompletePassed") -and ($Component.TestComponentStatus -ne "NotRun") ) {
                        "$($DeliveryController.MachineName) - $($Component.TestID) - $($Component.TestComponentStatus)" | Out-File $ErrorFile -append
                        $Status = "Component Failure"
                    }
                } 
            }
            if ( $Status -eq "Passed" ) { $EnvCheckUp++ }
            else { $EnvCheckDown++ }
        }
    }

    if ($DeliveryGroupCheck -eq "yes") {
        Write-Verbose "Delivery Groups Env Check started"
        $XDDeliveryGroups = Get-BrokerDesktopGroup -AdminAddress $AdminAddress

        foreach ( $DeliveryGroup in $XDDeliveryGroups ) {
            $Status = "Passed"
            Write-Verbose "Initialize Test Variables"
            Write-Verbose "Testing $($DeliveryGroup.Name)"
            $TestTarget = New-EnvTestDiscoveryTargetDefinition -AdminAddress $AdminAddress -TargetIdType "DesktopGroup" -TestSuiteId "DesktopGroup" -TargetId $DeliveryGroup.Uuid
            $TestResults = Start-EnvTestTask -AdminAddress $AdminAddress -InputObject $TestTarget -RunAsynchronously

            foreach ( $Result in $TestResults.TestResults ) {
                foreach ( $Component in $Result.TestComponents ) {
                    Write-Verbose "$($DeliveryGroup.Name) - $($Component.TestID) - $($Component.TestComponentStatus)"
                    if ( $Component.TestComponentStatus -ne "CompletePassed" -and ($Component.TestComponentStatus -ne "NotRun") ) {
                        "$(DeliveryGroup.Name) - $($Component.TestID) - $($Component.TestComponentStatus)`n" | Out-File $ErrorFile -Append
                        $Status = "Component Failure"
                    }
                }
            }
            if ( $Status -eq "Passed" ) { $EnvCheckUp++ }
            else { $EnvCheckDown++ }
        }
    }

    if ($CatalogCheck -eq "yes") {
        Write-Verbose "Catalog Env Check started"
        $XDCatalogs = Get-BrokerCatalog -AdminAddress $AdminAddress 

        foreach ( $Catalog in $XDCatalogs ) {
            $Status = "Passed"
            Write-Verbose "Initialize Test Variables"
            Write-Verbose "Testing $($Catalog.Name)"
            $TestTarget = New-EnvTestDiscoveryTargetDefinition -AdminAddress $AdminAddress -TargetIdType "Catalog" -TestSuiteId "Catalog" -TargetId $Catalog.Uuid
            $TestResults = Start-EnvTestTask -AdminAddress $AdminAddress -InputObject $TestTarget -RunAsynchronously
            foreach ( $Result in $TestResults.TestResults ) {
                foreach ( $Component in $Result.TestComponents ) {
                    Write-Verbose "$Catalog.Name - $($Component.TestID) - $($Component.TestComponentStatus)"
                    if ( ($Component.TestComponentStatus -ne "CompletePassed") -and ($Component.TestComponentStatus -ne "NotRun") ) {
                        "$Catalog.Name - $($Component.TestID) - $($Component.TestComponentStatus)" | Out-file $ErrorFile -append
                        $Status = "Component Failure"
                    }
                }            
            }
            if ( $Status -eq "Passed" ) { $EnvCheckUp++ }
            else { $EnvCheckDown++ }
        }
    }

    if ($HypervisorCheck -eq "yes") {
        Write-Verbose "Hypervisor Env Check started"
    
        foreach ($Connection in $HypervisorConnections) {
            $Status = "Passed"
            Write-Verbose "Initialize Test Variables"
            Write-Verbose "Testing $($Connection.Name)"

            $TestTarget = New-EnvTestDiscoveryTargetDefinition -AdminAddress $AdminAddress -TargetIdType "HypervisorConnection" -TestSuiteId "HypervisorConnection" -TargetId $Connection.HypHypervisorConnectionUid
            $TestResults = Start-EnvTestTask -AdminAddress $AdminAddress -InputObject $TestTarget -RunAsynchronously 
            foreach ( $Result in $TestResults.TestResults ) {
                foreach ( $Component in $Result.TestComponents ) {
                    Write-Verbose "$($Connection.Name) - $($Component.TestID) - $($Component.TestComponentStatus)"
                    if ( ($Component.TestComponentStatus -ne "CompletePassed") -and ($Component.TestComponentStatus -ne "NotRun") ) {
                        "$($Connection.Name) - $($Component.TestID) - $($Component.TestComponentStatus)" | Out-file $ErrorFile -Append
                        $Status = "Component Failure"
                    }
                }

            }       
            if ( $Status -eq "Passed" ) { $EnvCheckUp++ }
            else { $EnvCheckDown++ }
        
            Write-Verbose "Testing associated resources"

            #$HypervisorResources = Get-ProvTask -AdminAddress $AdminAddress | select HostingUnitName, HostingUnitUid -Unique | where HostingUnitName -notlike ""
            $HypervisorResources = Get-ChildItem XDHyp:\HostingUnits\* -AdminAddress $AdminAddress | Where-Object HypervisorConnection -like $Connection.Name

            # Check the resources
            foreach ($Resource in $HypervisorResources ) {
                $Status = "Passed"
                $TestTarget = New-EnvTestDiscoveryTargetDefinition -AdminAddress $AdminAddress -TargetIdType "HostingUnit" -TestSuiteId "HostingUnit" -TargetId $Resource.HostingUnitUid
                $TestResults = Start-EnvTestTask -AdminAddress $AdminAddress -InputObject $TestTarget -RunAsynchronously 
                foreach ( $Result in $TestResults.TestResults ) {
                    Write-Verbose "$($Connection.Name) - $($Resource.HostingUnitName) - $($Component.TestID) - $($Component.TestComponentStatus)"
                    foreach ( $Component in $Result.TestComponents ) {
                        if ( ($Component.TestComponentStatus -ne "CompletePassed") -and ($Component.TestComponentStatus -ne "NotRun") ) {
                            "$($Connection.Name) - $($Resource.HostingUnitName) - $($Component.TestID) - $($Component.TestComponentStatus)`n" | Outfile $ErrorFile -append   
                            $Status = "Component Failure"
                        }
                    }
                }
                if ( $Status -eq "Passed" ) { $EnvCheckUp++ }
                else { $EnvCheckDown++ }
            }
        }
    }

    Write-Verbose "Writing EnvCheck Data to output file"
    "envcheck-xd,$EnvCheckUp,$EnvCheckDown" | Out-File $OutputFile
}










}