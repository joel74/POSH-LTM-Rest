Function Invoke-F5RestMethod {
    [cmdletBinding(DefaultParameterSetName='Anonymous')]
    [OutputType([Xml.XmlDocument])]
    [OutputType([Microsoft.PowerShell.Commands.HtmlWebResponseObject])]
    [OutputType([String])]
    [OutputType([bool])]
    param ( 
        [Parameter(Mandatory)][Microsoft.PowerShell.Commands.WebRequestMethod]$Method,
        [Parameter(Mandatory)][uri]$URI,
        [Parameter(Mandatory)]$F5Session,

        $Body,
        $Headers,
        $ContentType,
        $ErrorMessage,
        [switch]$AsBoolean
    )

    try {
        # Remove params not understood by Invoke-RestMethod, so the remaining params can be splatted
        $null = $PSBoundParameters.Remove('AsBoolean')
        $null = $PSBoundParameters.Remove('F5Session')
        $null = $PSBoundParameters.Remove('ErrorMessage')
        if ($F5Session.WebSession.Headers.ContainsKey('X-F5-Auth-Token')) {
            $null = $PSBoundParameters.Add('WebSession', $F5Session.Websession)
        } else {
            $null = $PSBoundParameters.Add('Credential', $F5Session.Credential)
        }
        $Result = Invoke-RestMethodOverride @PSBoundParameters
        if ($AsBoolean) {
            $true
        } else {
            $Result
        }
    } catch {
        if ($AsBoolean) {
            $false
        } else {
            $message = $_.ErrorDetails.Message | ConvertFrom-json | Select-Object -expandproperty message
            $ErrorOutput = '"{0} {1}: {2}' -f $_.Exception.Response.StatusCode.value__,$_.Exception.Response.StatusDescription,(Invoke-NullCoalescing {$message} {$ErrorMessage}) 
            Write-Error $ErrorOutput
        } 
    }
}