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
        $WebSession,

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
				$Result = Invoke-RestMethod -Method $Method -Uri $URI -Credential $Credential -Body $Body -Headers $Headers -ContentType $ContentType;
			}
			WebSession {
				$Result = Invoke-RestMethod -Method $Method -Uri $URI -Body $Body -Headers $Headers -ContentType $ContentType -Websession $WebSession ;
			}
			Default {
				Throw("Either a PSCredential object or a WebSession object must be passed to Invoke-RestMethodOverride");
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
