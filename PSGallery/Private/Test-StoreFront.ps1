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
.NOTES
    Current Version:        1.0
    Creation Date:          22/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             22/02/2018          Function Creation
    David Brett             1.1             29/03/2018          Returns Object

.EXAMPLE
    None Required
#>

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$StoreFrontServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$StoreFrontPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$StoreFrontPath,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$StoreFrontProtocol,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile
    )

    #Create array with results
    $results = @()

    # Initialize Arrays and Variables
    Write-Verbose "Variables and Arrays Initalized"

    Write-Verbose "Read in StoreFront Server List Port and StoreFront Path"
    Write-Verbose "StoreFront Servers: $StoreFrontServers"
    Write-Verbose "StoreFront Port: $StoreFrontPortString" 
    Write-Verbose "StoreFront Path: $StoreFrontPath"
    Write-Verbose "StoreFront Protocol: $StoreFrontProtocol" 
    
    # Loop through StoreFront Servers
    Write-Verbose "Looping through StoreFront Servers and running monitoring checks"
    foreach ($StoreFrontServer in $StoreFrontServers) { 

        # Tests
        $ping = $false
        $sfport = $false
        $sfsite = $false
	
        # If StoreFront Server is UP then log to Console and Increment UP Count
        if ((Connect-Server $StoreFrontServer) -eq "Successful") {
            Write-Verbose "$StoreFrontServer is up" 
            $ping = $true

            # If StoreFront Server Port is UP log to Console and Increment UP Port Count
            if ((Test-NetConnection $StoreFrontServer $StoreFrontPortString).open -eq "True") {
                Write-Verbose "$StoreFrontServer Port is up: Port - $StoreFrontPortString"
                $sfport = $true

                # Test Connection to defined Store Web Site
                $ConcatURL = $StoreFrontProtocol + "://" + $StoreFrontServer + $StoreFrontPath

                if ((Test-Url $ConcatURL) -eq "good") {
                    Write-Verbose "$StoreFrontServer Web Site and Store is up: $ConcatURL"
                    $sfsite = $true
                }
                else {
                    Write-Verbose "$StoreFrontServer Web Site and Store is down: $ConcatURL"
                    "$StoreFrontServer Web Site and Store is down: $ConcatURL" | Out-File $ErrorFile -Append
                    $sfsite = $false
                }
            }
            else {
                Write-Verbose "$StoreFrontServer Port is down - Port - $StoreFrontPortString" 
                "$StoreFrontServer Port is down - Port - $StoreFrontPortString" | Out-File $ErrorFile -Append
                $sfport = $false
            }
        }
        else {
            Write-Verbose "$StoreFrontServer is down"
            "$StoreFrontServer is down"  | Out-File $ErrorFile -Append
            $ping = $false
        }

        # Add results to array
        $results += [PSCustomObject]@{
            'Server'            = $StoreFrontServer
            'Ping'              = $ping
            'StoreFrontPort'    = $sfport
            'StoreFrontSite'    = $sfsite
        }

    }

    #returns object with test results
    return $results
	
}
