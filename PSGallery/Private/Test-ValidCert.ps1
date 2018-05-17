function Test-ValidCert {
    <#   
.SYNOPSIS   
    Checks the validity of a remote certificate presented on a port, as seen by host the function is run on 
.DESCRIPTION 
    Checks the validity of a remote certificate presented on a port, as seen by host the function is run on.
.PARAMETER Target
    Host you want to check the certificate of.  Can be hostname or IP. 
.PARAMETER Port
    Specifies the ports to run checks against
.NOTES
    Current Version:        1.0
    Creation Date:          14/05/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough         1.0             22/02/2018          Function Creation
.CREDIT
    Original code by Rob VandenBrink, https://bit.ly/2IDf5Gd
.OUTPUT
    Returns boolean value.  $true / $false
.EXAMPLE
    None Required
#>

    param ( 
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Target, 
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][int]$Port
    )
    
    $TCPClient = New-Object -TypeName System.Net.Sockets.TCPClient
    try {
        $TcpSocket = New-Object Net.Sockets.TcpClient($Target, $Port)
        $tcpstream = $TcpSocket.GetStream()
        $Callback = { param($sender, $cert, $chain, $errors) return $true }
        $SSLStream = New-Object -TypeName System.Net.Security.SSLStream -ArgumentList @($tcpstream, $True, $Callback)
        try {
            $SSLStream.AuthenticateAsClient($Target)
            $Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($SSLStream.RemoteCertificate)
        }
        finally {
            $SSLStream.Dispose()
        }
    }
    finally {
        $TCPClient.Dispose()
    }

    return $Certificate.Verify() 
}