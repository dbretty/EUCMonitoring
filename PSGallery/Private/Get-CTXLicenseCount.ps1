function Get-CTXLicenseCount {
    <#   
.SYNOPSIS   
    Checks the ports and services of a Windows Server.
.DESCRIPTION 
    Checks the ports and services of a Windows Server.  
.PARAMETER ComputerName
    Single Instance Computer to run checks against
.PARAMETER Ports 
    Specifies the ports to run checks against
.PARAMETER Services 
    Specifies the windows services to run checks against
.NOTES
    Current Version:        1.0
    Creation Date:          14/05/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough         1.0             22/02/2018          Function Creation
    
.EXAMPLE
    None Required
#>
    Param ( 
        $ComputerName,
        $LicenseType
    )
    begin {}

    process {
        try {
            $Available = 0
            $Total = 0
            $Cert = Get-LicCertificate -AdminAddress $ComputerName
            $LicenseResults = Get-LicInventory -AdminAddress $ComputerName -CertHash $Cert.CertHash
            foreach ( $License in $LicenseResults ) {
                write-Output "License Type: $($License.LicenseProductName)"
                $Available += $License.LicensesAvalable
                $Total += $License.LicensesInUse
            }
            Write-Output "Total: $Total"
            Write-Output "Available: $Available"
            return $Results | Select-Object LicensesInUse, LicensesAvailable
        } 
        catch [Exception] {
            Write-Output "$computer $($_.Exception.Message)"
            return $False
        }
    }

    end {}


}