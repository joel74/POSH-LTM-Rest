Function Invoke-RestMethodOverride {
    [cmdletBinding(DefaultParameterSetName='Anonymous')]
    [OutputType([Xml.XmlDocument])]
    [OutputType([Microsoft.PowerShell.Commands.HtmlWebResponseObject])]
    [OutputType([String])]
    [OutputType([bool])]
    param ( 
        [Parameter(Mandatory=$true)][Microsoft.PowerShell.Commands.WebRequestMethod]$Method,
        [Parameter(Mandatory=$true)][uri]$URI,

        [System.Management.Automation.PSCredential]
        $Credential,

        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession=(New-Object Microsoft.PowerShell.Commands.WebRequestSession),

        $Body,
        $Headers,
        $ContentType
    )
    [SSLValidator]::OverrideValidation()

    Invoke-RestMethod @PSBoundParameters

    [SSLValidator]::RestoreValidation()
}