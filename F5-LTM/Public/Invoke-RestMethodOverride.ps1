Function Invoke-RestMethodOverride {
    [cmdletBinding(DefaultParameterSetName='Anonymous')]
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

        switch($PSCmdLet.ParameterSetName) {
            Credential {
                # 1) LTM version request
                # 2) LTM token request (LTM -ge 11.6)
                # 3) External caller with -Credential
                $Result = Invoke-RestMethod -Method $Method -Uri $URI -Body $Body -Headers $Headers -ContentType $ContentType -Credential $Credential
            }
            WebSession {
                if ($WebSession.Headers.Count -eq 0 -and $WebSession.Credentials) {
                    # 4) LTM -lt 11.6, use [F5Session.]WebSession.Credentials
                    $Credential = New-Object System.Management.Automation.PSCredential($WebSession.Credentials.UserName, $WebSession.Credentials.SecurePassword)
                    $Result = Invoke-RestMethod -Method $Method -Uri $URI -Body $Body -Headers $Headers -ContentType $ContentType -Credential $Credential
                } else {
                    # 5) LTM -ge 11.6), uses 'X-F5-Auth-Token'
                    # 6) External caller with -WebSession
                    $Result = Invoke-RestMethod -Method $Method -Uri $URI -Body $Body -Headers $Headers -ContentType $ContentType -Websession $WebSession
                }
            }
            Default {
                # 7) External caller with no -Credential nor -WebSession specified
                Invoke-RestMethod -Method $Method -Uri $URI -Body $Body -Headers $Headers -ContentType $ContentType;
            }
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