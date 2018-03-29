function Get-vServer {
    <#   
.SYNOPSIS   
    Build a Global Variable with all current vServer Status.
.DESCRIPTION 
    Build a Global Variable with all current vServer Status.
.PARAMETER NSIP 
    NetScaler IP to Connect To 
.NOTES
    Current Version:        1.0
    Creation Date:          12/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             12/03/2018          Function Creation
    Ryan Butler             1.1             27/03/2018          Added in nsession parameter
.EXAMPLE
    None Required
#> 

    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$NSIP,
        [parameter(Mandatory = $true, ValueFromPipeline = $false)]$NSSession

    )

    # Build Global Variables with all Load Balance vServers on NetScaler
    Write-Verbose "Return all Virtual Servers on $NSIP"
    $vServers = Invoke-RestMethod -uri "$NSIP/nitro/v1/stat/lbvserver" -WebSession $NSSession.WebSession -Method GET

    Return $vServers
}
