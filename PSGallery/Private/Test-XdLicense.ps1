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
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$AdminAddress
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

        Write-Output "Not complete."

    }

    End { }
}