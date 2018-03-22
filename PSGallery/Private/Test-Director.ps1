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
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DirectorServers,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DirectorPortString,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DirectorPath,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$DirectorProtocol,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$ErrorFile,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$OutputFile

    )

    # Initialize Arrays and Variables
    $DirectorUp = 0
    $DirectorDown = 0
    Write-Verbose "Variables and Arrays Initalized"

    Write-Verbose "Read in Director Server List Port and Director Path"
    Write-Verbose "Director Servers: $DirectorServers"
    Write-Verbose "Director Port: $DirectorPortString" 
    Write-Verbose "Director Path: $DirectorPath"
    Write-Verbose "Director Protocol: $DirectorProtocol" 
    
    # Loop through Director Servers
    Write-Verbose "Looping through Director Servers and running monitoring checks"
    foreach ($DirectorServer in $DirectorServers) { 
	
        # If Director Server is UP then log to Console and Increment UP Count
        if ((Connect-Server $DirectorServer) -eq "Successful") {
            Write-Verbose "$DirectorServer is up" 

            # If Director Server Port is UP log to Console and Increment UP Port Count
            if ((Test-NetConnection $DirectorServer $DirectorPortString).open -eq "True") {
                Write-Verbose "$DirectorServer Port is up: Port - $DirectorPortString"

                # Test Connection to defined Store Web Site
                $ConcatURL = $DirectorProtocol + "://" + $DirectorServer + $DirectorPath

                if ((Test-Url $ConcatURL) -eq "good") {
                    Write-Verbose "$DirectorServer Web Site is up: $ConcatURL"
                    $DirectorUp++
                }
                else {
                    Write-Verbose "$DirectorServer Web Site is down: $ConcatURL"
                    "$DirectorServer Web Site is down: $ConcatURL" | Out-File $ErrorFile -Append
                    $DirectorDown++
                }
            }
            else {
                Write-Verbose "$DirectorServer Port is down - Port - $DirectorPortString" 
                "$DirectorServer Port is down - Port - $DirectorPortString" | Out-File $ErrorFile -Append
                $DirectorDown++
            }
        }
        else {
            Write-Verbose "$DirectorServer is down"
            "$DirectorServer is down"  | Out-File $ErrorFile -Append
            $DirectorDown++
        }
    }

    # Write Data to Output File
    Write-Verbose "Writing Director Data to output file"
    "director,$DirectorUp,$DirectorDown" | Out-File $OutputFile
	
}
