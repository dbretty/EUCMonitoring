function Get-XDLicenseCount {
        <#   
.SYNOPSIS   
    Grabs Citrix license data
.DESCRIPTION 
    Grabs Citrix license data  
.PARAMETER LicenseServer
    Citrix License Server
.NOTES
    Name                    Version         Date                Change Detail
    Ryan Butler             1.0             29/03/2018          Function Creation
.EXAMPLE
    None Required
#> 
[CmdletBinding()]
Param
(
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]$LicenseServer

)

$LicenseData = Get-CimInstance -class "Citrix_GT_License_Pool" -namespace "ROOT\CitrixLicensing" -ComputerName $LicenseServer

$results = @()
if ($LicenseData )
{
    foreach ($lic in $LicenseData )
    {
        $results += [PSCustomObject]@{
        "LicenseName"  = $lic.PLD
        "Count" = $lic.Count
        "InUseCount" = $lic.InUseCount
        "LicenseType" = $lic.LicenseType
        "SubscriptionDate" = $lic.SubscriptionDate
        }
    }
return $results
}
else {
    Write-Warning "Could not pull license data"
return $false
}

}