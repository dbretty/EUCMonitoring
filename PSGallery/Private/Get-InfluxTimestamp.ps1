
function Get-InfluxTimestamp {
    <#   
.SYNOPSIS   
    Checks the ports and services of a Windows Server.
.DESCRIPTION 
    Checks the ports and services of a Windows Server.  
.PARAMETER JSONFile
    Specify path to your config file to run checks against.  This would be your EUCMonitoring.json, or your
    test configs.  Specifying a JSONFile override any ConfigObject passed to it.  This is mainly 
    used in unit testing to validate the test suites before production. 
.PARAMETER ConfigObject
    Specifies the ports to run checks against.  This should already be in the target location.
.PARAMETER Services 
    Specifies the windows services to run checks against
.NOTES
    Current Version:        1.0
    Creation Date:          14/05/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough         1.0             22/02/2018          Function Creation
    
.EXAMPLE
    Test-Template -JSONFile "C:\Monitoring\EUCMonitoring.json"
#>
    $DateTime = Get-Date 
    $utcDate = $DateTime.ToUniversalTime()
    # Convert to a Unix time as a double, noticed that it gets all the seconds down in the decimal if cast as a double.
    $unixTime = [double]((Get-Date -Date $utcDate -UFormat %s))
    # multiply seconds to move the decimal place.
    $nano = $unixTime * 1000000000
    #cast as a int64 gets rid of the decimal and scientific notation.
    return [int64]$nano
}