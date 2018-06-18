Function Test-PVS { 
    <#
.SYNOPSIS
Test that the PVS server is returning values.  Not production Ready

.DESCRIPTION
Test that the PVS server is returning values.  Not production Ready

.PARAMETER PVSServer
Target PVS Server

.NOTES
    Current Version:        1.0
    Creation Date:          17/06/2018
    Initial idea from Guy Leach, https://guyrleech.wordpress.com/
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough         1.0             17/06/2018          Function Creation

#>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$PVSServer
    )

    $Results = @()

    $ctxsnap = add-pssnapin citrix.pvs* -ErrorAction SilentlyContinue
    $ctxsnap = get-pssnapin citrix.pvs* -ErrorAction SilentlyContinue

    if ($null -eq $ctxsnap) {
        Write-error "PVS Powershell Snapin Load Failed - No Provisiong Services SDK Found"
        Write-error "Cannot Load PVS SDK"
        Return # Fix Termination of Powershell instance https://git.io/vxEGW
    }
    else {
        Write-Verbose "Provisioning Services Powershell SDK Snapin Loaded"
    }

    $DeviceCount = 0
    $Retries = 0

    if ( Get-Command -Name Set-PvsConnection -ErrorAction SilentlyContinue ) {
        Set-PvsConnection -Server $PVSServer
        ## Status is comma separated value where first field is the number of retries
        #$pvsRetries += Get-PvsDeviceInfo | `
        #    Select-Object -Property Name, @{n = 'PVS Server'; e = {$_.ServerName}}, SiteName, CollectionName, `
        #    DiskLocatorName, @{n = 'Retries'; e = {($_.status -split ',')[0] -as [int]}}, DiskVersion
        $PVSDeviceInfo = Get-PvsDeviceInfo
        $DeviceCount = $PVSDeviceInfo.Count
        $PVSDeviceInfo | ForEach-Object { $Retries += [int]($_.Status -Split ',')[0] }

    }
    else {
        Write-Warning "PVS cmdlets not detected so unable to report on PVS server $pvs"
        return $False
    }

    $Results += [PSCustomObject]@{
        'DeviceCount' = $DeviceCount
        'Retries'     = $Retries
    }

}
