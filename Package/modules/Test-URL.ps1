function Test-URL {
    <#
.SYNOPSIS
    Tests connectivity to a URL
.DESCRIPTION
    Tests connectivity to a URL
.PARAMETER Url
    The URL to be tested
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
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Url
    )

    Write-Verbose "Connecting to URL: $URL"

    $HTTP_Status = 400

    # Setup Request Object
    $HTTP_Request = [System.Net.WebRequest]::Create("$URL")

    #Check for Response
    try {
        $HTTP_Response = $HTTP_Request.GetResponse() 
    }
    catch {
        return "bad"
        break
    }
    #Extract Response Code
    $HTTP_Status = [int]$HTTP_Response.StatusCode
	
    If ($HTTP_Status -eq 200) { 
        return "good" 
    }
    else {
        return "bad"
    }./

}
