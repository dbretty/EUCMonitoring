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
#Try to connect to license server and pull data
try {
$LicenseData = Get-CimInstance -class "Citrix_GT_License_Pool" -namespace "ROOT\CitrixLicensing" -ComputerName $LicenseServer -ErrorAction stop
}
catch{
    Write-error "Could not pull license data from license server"
    return $false
}

#Create results array
$results = @()

if ($LicenseData )
{
    #Create custom object for each license found and add to results
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
    Write-Warning "No license data found"
return $false
}

}