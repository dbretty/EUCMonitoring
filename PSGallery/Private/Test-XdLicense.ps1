Function Test-XdLicense {
    <#
    .SYNOPSIS
    Console based output
    
    .DESCRIPTION
    Long description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$LicenseServer,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$LicenseType
    )
    
    Begin { 
        $ctxsnap = add-pssnapin Citrix.Licensing.* -ErrorAction SilentlyContinue
        $ctxsnap = get-pssnapin Citrix.Licensing.* -ErrorAction SilentlyContinue

        if ($null -eq $ctxsnap) {
            Write-Error "Citrix Licensing Powershell Snapin Load Failed"
            Write-Error "Cannot Load Citrix Licensing Powershell SDK"
            Return $false 
        }
        else {
            Write-Verbose "Citrix Licensing SDK Snapin Loaded"
        }
    }

    Process {
        $Results = @()
        $Errors = @()

        $Cert = Get-LicCertificate -AdminAddress $LicenseServer

        $TotalAvailable = 0
        $TotalIssued = 0

        $LicResults = Get-LicInventory -AdminAddress $LicenseServer -CertHash $cert.CertHash
        foreach ($License in $LicResults) {
            if ($License.LicenseProductName -eq $LicenseType) {
                $TotalIssued += $License.LicensesInUse
                $TotalAvailable += ($License.LicensesAvailable - $License.LicenseOverdraft)
            }
        }

        Write-Verbose "TotalIssued    = $TotalIssued"
        Write-Verbose "TotalAvailable = $TotalAvailable"
        Write-Verbose "LicenseType    = $LicenseType"

        $Results += [PSCustomObject]@{
            'TotalIssued'    = $TotalIssued
            'TotalAvailable' = $TotalAvailable
            'LicenseType'    = $LicenseType
            'Errors'         = $Errors
        }

        return $Results
    }

    End { }
}