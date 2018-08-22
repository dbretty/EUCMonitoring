function Test-Service {

    <#   
.SYNOPSIS   
    Tests a service passed into the function
.DESCRIPTION 
    Tests a service passed into the function   
.PARAMETER ServerName 
    The Server Name to test the service on
.PARAMETER ServiceName 
    The Service Name to test
.NOTES
    Current Version:        1.0
    Creation Date:          19/02/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    James Kindon            1.0             27/03/2017          Function Creation
    David Brett             1.1             19/02/2018          Edited Function to accept input variables and return status
    David Brett             1.2             16/06/2018          Updated Parameters and switched function to advanced
.EXAMPLE
    None Required     
#> 

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$ServerName,
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]$ServiceName
    )

    # Get Service Status
    Write-Verbose "Testing Service Status for $ServiceName on $ServerName"
    $ServiceStatus = (Get-Service -ErrorAction SilentlyContinue -ComputerName $ServerName -Name $ServiceName).Status
    if ($ServiceStatus -eq "Running") {
        Write-Verbose "$ServiceName on $ServerName is Running"
    }
    else {
        Write-Verbose "$ServiceName on $ServerName is Degraded or Stopped"
    }
    
    return $ServiceStatus

}
