

# Straight lifted from Ed Wilson, https://bit.ly/2wUQw2C


Function Test-CommandExists
{

    Param ($command)

    $oldPreference = $ErrorActionPreference

    $ErrorActionPreference = 'stop'

    try { if ( Get-Command $command ) { "$command exists" } }

    Catch { Write-Host "$command does not exist" }

    Finally { $ErrorActionPreference = $oldPreference }

} #end function test-CommandExists