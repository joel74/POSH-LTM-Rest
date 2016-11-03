Function Invoke-RestMethodOverride {
    [cmdletBinding()]
    [OutputType([Xml.XmlDocument])]
    [OutputType([Microsoft.PowerShell.Commands.HtmlWebResponseObject])]
    [OutputType([String])]
    [OutputType([bool])]
    param ( 
        [Parameter(Mandatory=$true)][string]$Method,
        [Parameter(Mandatory=$true)][string]$URI,

        [Parameter(Mandatory=$false,ParameterSetName='Credential')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(Mandatory=$false,ParameterSetName='WebSession')]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession=(New-Object Microsoft.PowerShell.Commands.WebRequestSession),

        [Parameter(Mandatory=$false)]$Body=$null,
        [Parameter(Mandatory=$false)]$Headers=$null,
        [Parameter(Mandatory=$false)]$ContentType=$null,
        [Parameter(Mandatory=$false)]$ErrorMessage=$null,
        [switch]$AsBoolean
    )
    try {
        [SSLValidator]::OverrideValidation()

        if (!$Credential -and $WebSession.Headers.Count -eq 0 -and $WebSession.Credentials) {
            # LTM -lt 11.6, use F5Session.WebSession.Credentials
            $Credential = New-Object System.Management.Automation.PSCredential($WebSession.Credentials.UserName, (ConvertTo-SecureString $WebSession.Credentials.Password -AsPlainText -Force))
        }
        if ($Credential) {
            # LTM -lt 11.6, use F5Session.WebSession.Credentials
            $Result = Invoke-RestMethod -Method $Method -Uri $URI -Body $Body -Headers $Headers -ContentType $ContentType -WebSession $WebSession -Credential $Credential;
        } else {
            # LTM -ge 11.6, use 'X-F5-Auth-Token'
            $Result = Invoke-RestMethod -Method $Method -Uri $URI -Body $Body -Headers $Headers -ContentType $ContentType -WebSession $WebSession;
        }

        [SSLValidator]::RestoreValidation()
        
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
