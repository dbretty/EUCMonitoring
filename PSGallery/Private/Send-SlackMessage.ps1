function Send-SlackMessage {
    <#   
.SYNOPSIS   
    Sends a message to Slack
.DESCRIPTION 
    Sends a message to Slack
.PARAMETER WebHookUri 
    WebHookUri
.PARAMETER Message 
    Message to Send
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
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$WebHookUri,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Message
    )

    $payload = @{
        "text" = $Message
    }

    Invoke-WebRequest `
        -Body (ConvertTo-Json -Compress -InputObject $payload) `
        -Method Post `
        -Uri $WebHookUri | Out-Null
}
