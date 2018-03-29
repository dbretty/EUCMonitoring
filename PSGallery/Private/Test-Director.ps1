function Test-Director {
    <#   
.SYNOPSIS   
    Checks the Status of the Director Server Passed In
.DESCRIPTION 
    Checks the Status of the Director Server Passed In
.PARAMETER DirectorServers 
    Comma Delimited List of Director to check
.PARAMETER DirectorPortString 
    TCP Port to use for Director Connectivity Tests
.PARAMETER DirectorPath 
    Path to Director Home Page
.PARAMETER DirectorProtocol 
    Protocol to use to test
.PARAMETER ErrorFile 
    Infrastructure Error File to Log To
.NOTES
    Current Version:        1.0
    Creation Date:          22/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             22/02/2018          Function Creation
    David Brett             1.1             29/03/2018          Return Object
.EXAMPLE
    None Required
#>

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DirectorServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DirectorPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DirectorPath,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DirectorProtocol,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile
    )

    #Create array with results
    $results = @()

    # Initialize Arrays and Variables
    Write-Verbose "Variables and Arrays Initalized"

    Write-Verbose "Read in Director Server List Port and Director Path"
    Write-Verbose "Director Servers: $DirectorServers"
    Write-Verbose "Director Port: $DirectorPortString" 
    Write-Verbose "Director Path: $DirectorPath"
    Write-Verbose "Director Protocol: $DirectorProtocol" 
    
    # Loop through Director Servers
    Write-Verbose "Looping through Director Servers and running monitoring checks"
    foreach ($DirectorServer in $DirectorServers) { 
        
        # Tests
        $ping = $false
        $dirport = $false
        $dirsite = $false

        # If Director Server is UP then log to Console and Increment UP Count
        if ((Connect-Server $DirectorServer) -eq "Successful") {
            Write-Verbose "$DirectorServer is up" 
            $ping = $true

            # If Director Server Port is UP log to Console and Increment UP Port Count
            if ((Test-NetConnection $DirectorServer $DirectorPortString).open -eq "True") {
                Write-Verbose "$DirectorServer Port is up: Port - $DirectorPortString"
                $dirport = $true

                # Test Connection to defined Store Web Site
                $ConcatURL = $DirectorProtocol + "://" + $DirectorServer + $DirectorPath

                if ((Test-Url $ConcatURL) -eq "good") {
                    Write-Verbose "$DirectorServer Web Site is up: $ConcatURL"
                    $dirsite = $true
                }
                else {
                    Write-Verbose "$DirectorServer Web Site is down: $ConcatURL"
                    "$DirectorServer Web Site is down: $ConcatURL" | Out-File $ErrorFile -Append
                    $dirsite = $false
                }
            }
            else {
                Write-Verbose "$DirectorServer Port is down - Port - $DirectorPortString" 
                "$DirectorServer Port is down - Port - $DirectorPortString" | Out-File $ErrorFile -Append
                $dirport = $false
            }
        }
        else {
            Write-Verbose "$DirectorServer is down"
            "$DirectorServer is down"  | Out-File $ErrorFile -Append
            $ping = $false
        }

        # Add results to array
        $results += [PSCustomObject]@{
            'Server'         = $DirectorServer
            'Ping'           = $ping
            'DirectorPort'   = $dirport
            'DirectorSite'   = $dirsite
        }

    }

    #returns object with test results
    return $results
	
}
