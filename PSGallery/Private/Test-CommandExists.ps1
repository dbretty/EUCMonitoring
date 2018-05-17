

# Straight lifted from Ed Wilson, https://bit.ly/2wUQw2C


Function Test-CommandExists {
    <#
    .SYNOPSIS
    Make sure that our generated functions work. 
    
    .DESCRIPTION
    Long description
    
    .PARAMETER command
    Parameter description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>

    Param ($command)

    $oldPreference = $ErrorActionPreference

    $ErrorActionPreference = 'stop'

    try { if ( Get-Command $command ) { "$command exists" } }

    Catch { Write-Host "$command does not exist" }

    Finally { $ErrorActionPreference = $oldPreference }

} #end function test-CommandExists