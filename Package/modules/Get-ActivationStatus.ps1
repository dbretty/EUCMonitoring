function Get-ActivationStatus {
    <#   
.SYNOPSIS   
    Gets the activation status for a server passed in
.DESCRIPTION 
   Gets the activation status for a server passed in
.PARAMETER ComputerName 
    The Server to check the activation status
.NOTES
    Current Version:        1.0
    Creation Date:          19/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             19/02/2018          Function Creation
.EXAMPLE
    None Required
#>

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ComputerName
    )

    begin {}
    
    process {
        try {
            $wpa = Get-WmiObject SoftwareLicensingProduct -ComputerName $ComputerName -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f'" -Property LicenseStatus -ErrorAction Stop
        }
        catch {
            $status = New-Object ComponentModel.Win32Exception ($_.Exception.ErrorCode)
            $wpa = $null    
        }
        $out = New-Object psobject -Property @{
            ComputerName = $ComputerName;
            Status       = [string]::Empty;
        }
        if ($wpa) {
            :outer foreach ($item in $wpa) {
                switch ($item.LicenseStatus) {
                    0 {$out.Status = "Unlicensed"}
                    1 {$out.Status = "Licensed"; break outer}
                    2 {$out.Status = "Out-Of-Box Grace Period"; break outer}
                    3 {$out.Status = "Out-Of-Tolerance Grace Period"; break outer}
                    4 {$out.Status = "Non-Genuine Grace Period"; break outer}
                    5 {$out.Status = "Notification"; break outer}
                    6 {$out.Status = "Extended Grace"; break outer}
                    default {$out.Status = "Unknown value"}
                }
            }
        }
        else {$out.Status = $status.Message}
        Return $out.status
    }

    end {}
}
