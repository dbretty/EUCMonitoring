function Test-StoreFront {
    <#   
.SYNOPSIS   
    Checks the Status of the StoreFront Passed In
.DESCRIPTION 
    Checks the Status of the StoreFront Passed In
.PARAMETER StoreFrontServers 
    Comma Delimited List of XenServer Pool Masters to check
.PARAMETER StoreFrontPortString 
    TCP Port to use for XenServer Connectivity Tests
.PARAMETER StoreFrontPath 
    Infrastructure Error File to Log To
.PARAMETER StoreFrontProtocol 
    Infrastructure OutputFile
.PARAMETER ErrorFile 
    Infrastructure Error File to Log To
.PARAMETER OutputFile 
    Infrastructure OutputFile
.NOTES
    Current Version:        1.0
    Creation Date:          22/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             22/02/2018          Function Creation

.EXAMPLE
    None Required
#>

    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$StoreFrontServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$StoreFrontPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$StoreFrontPath,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$StoreFrontProtocol,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$OutputFile

    )

    # Initialize Arrays and Variables
    $StoreFrontUp = 0
    $StoreFrontDown = 0
    Write-Verbose "Variables and Arrays Initalized"

    # Get StoreFront Server Comma Delimited List Port and Store Path
    $StoreFrontServers = $StoreFrontServers.Split(",")
    Write-Verbose "Read in StoreFront Server List Port and StoreFront Path"
    Write-Verbose "StoreFront Servers: $StoreFrontServers"
    Write-Verbose "StoreFront Port: $StoreFrontPortString" 
    Write-Verbose "StoreFront Path: $StoreFrontPath"
    Write-Verbose "StoreFront Protocol: $StoreFrontProtocol" 
    
    # Loop through StoreFront Servers
    Write-Verbose "Looping through StoreFront Servers and running monitoring checks"
    foreach ($StoreFrontServer in $StoreFrontServers) { 
	
        # If StoreFront Server is UP then log to Console and Increment UP Count
        if ((Connect-Server $StoreFrontServer) -eq "Successful") {
            Write-Verbose "$StoreFrontServer is up" 

            # If StoreFront Server Port is UP log to Console and Increment UP Port Count
            if ((Test-NetConnection $StoreFrontServer $StoreFrontPortString).open -eq "True") {
                Write-Verbose "$StoreFrontServer Port is up: Port - $StoreFrontPortString"

                # Test Connection to defined Store Web Site
                $ConcatURL = $StoreFrontProtocol + "://" + $StoreFrontServer + $StoreFrontPath

                if ((Test-Url $ConcatURL) -eq "good") {
                    Write-Verbose "$StoreFrontServer Web Site and Store is up: $ConcatURL"
                    $StoreFrontUp++
                }
                else {
                    Write-Verbose "$StoreFrontServer Web Site and Store is down: $ConcatURL"
                    "$StoreFrontServer Web Site and Store is down: $ConcatURL" | Out-File $ErrorFile -Append
                    $StoreFrontDown++
                }
            }
            else {
                Write-Verbose "$StoreFrontServer Port is down - Port - $StoreFrontPortString" 
                "$StoreFrontServer Port is down - Port - $StoreFrontPortString" | Out-File $ErrorFile -Append
                $StoreFrontDown++
            }
        }
        else {
            Write-Verbose "$StoreFrontServer is down"
            "$StoreFrontServer is down"  | Out-File $ErrorFile -Append
            $StoreFrontDown++
        }
    }

    # Write Data to Output File
    Write-Verbose "Writing StoreFront Data to output file"
    "storefront,$StoreFrontUp,$StoreFrontDown" | Out-File $OutputFile
	
}
