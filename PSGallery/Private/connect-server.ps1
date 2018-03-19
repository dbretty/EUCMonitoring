function Connect-Server {
    <#
.SYNOPSIS
    Tests connectivity to a server
.DESCRIPTION
    Tests connectivity to a server
.PARAMETER ServerName
    The server name that you would like to test connectivity to
.NOTES
    Current Version:        1.0
    Creation Date:          07/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             07/02/2018          Function Creation

.EXAMPLE
    None Required
#>

    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][String[]]$ServerName
    )

    #Log and Test Network Connectivity
    Write-Verbose "Connecting to Server: $ServerName"
    $Result = Test-Connection $ServerName -Count 2 -Quiet
    if ($Result -eq $True) {
        Write-Verbose "Connection to $ServerName successful"
        Return "Successful"
    }
    else {
        Write-Verbose "Connection to $ServerName failed"
        Return "Failed"
    }
}
