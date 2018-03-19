function Test-NetScaler {
    <#   
.SYNOPSIS   
    Tests Citrix NetScaler.
.DESCRIPTION 
    Logs into a NetScaler ADC and creates a global variable called $NSSession to be used to invoke NITRO Commands, then tests the vServer Status.          
    Currently Testing
        NetScaler ADC Status
        vServer Health Status (UP/DOWN/DEGRADED)
.PARAMETER NetScalers 
    Comma Delimited List of NetScalers
.PARAMETER UserName 
    Username to use to check the NetScaler
.PARAMETER Password 
    Password to use to log into the NetScaler
.PARAMETER ErrorFile 
    Infrastructure Error File to Log To
.PARAMETER OutputFile 
    Infrastructure OutputFile   
.NOTES
    Current Version:        1.0
    Creation Date:          12/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             12/03/2018          Function Creation
.EXAMPLE
    None Required
#> 

    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$NetScalers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$UserName,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Password,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$OutputFile

    )

    # Initialize Arrays and Variables
    $NetScalerUp = 0
    $NetScalerDown = 0
    $vServerUp = 0
    $vServerDown = 0
    Write-Verbose "Variables and Arrays Initalized"

    # Get NetScaler List from Registry
    Write-Verbose "Read NetScalers"
    $NetScalers = $NetScalers.Split(",")

    # Loop through NetScalers pulled from Registry
    Write-Verbose "Looping through NetScalers and running monitoring checks"
    foreach ($NetScaler in $NetScalers) { 

        # If NetScaler is UP then log to Console and Increment UP Count
        if ((Connect-Server $NetScaler) -eq "Successful") {
            Write-Verbose "NetScaler - $NetScaler is up"
            $NetScalerUp++

            # If NetScaler up log Log in and grab vServer Status
            Connect-NetScaler $NetScaler $UserName $Password
            Write-Verbose "NetScaler - $NetScaler Logged In"

            $vServers = Get-vServers $NetScaler
				
            # Loop Through vServers and check Status
            Write-Verbose "Looping through vServers to check status"
            foreach ($vServer in $vServers.lbvserver) {
                $vServerName = $vServer.name
                if ($vServer.State -eq "UP") {
                    Write-Verbose "$vServerName is up"
                    $vServerUp++
                    if ($vserver.vslbhealth -ne 100) {
                        Write-Verbose "$vServerName is Degraded"
                        "$vServerName is Degraded" | Out-File $ErrorFile -Append
                    }
                }
                else {
                    Write-Verbose "$vServerName is Down"
                    "$vServerName is Down" | Out-File $ErrorFile -Append
                    $vServerDown++
                }
            }
        }
        else {
            Write-Verbose "NetScaler - $NetScaler is down"
            "NetScaler - $NetScaler is down" | Out-File $ErrorFile -Append
            $NetScalerDown++
        }
    }

    # Write Data to Output File
    Write-Verbose "Writing NetScaler Data to output file"
    "netscaler,$NetScalerUp,$NetScalerDown" | Out-File $OutputFile
    "vserver,$vServerUp,$vServerDown" | Out-File $OutputFile -Append
}
