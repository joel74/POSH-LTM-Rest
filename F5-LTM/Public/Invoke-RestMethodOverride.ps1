Function Invoke-RestMethodOverride {
    [cmdletBinding()]
    param ( 
        [Parameter(Mandatory=$true)][string]$Method,
        [Parameter(Mandatory=$true)][string]$URI,
        [Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory=$false)]$Body=$null,
        [Parameter(Mandatory=$false)]$Headers=$null,
        [Parameter(Mandatory=$false)]$ContentType=$null,
        [Parameter(Mandatory=$false)]$ErrorMessage=$null,
        [switch]$AsBoolean
    )
    try {
        [SSLValidator]::OverrideValidation()

        $Result = Invoke-RestMethod -Method $Method -Uri $URI -Credential $Credential -Body $Body -Headers $Headers -ContentType $ContentType 

        [SSLValidator]::RestoreValidation()
        
        if ($AsBoolean) {
            $true
        } else {
            $Result
        }
    } catch {
        #Write-Error ('"{0}-{1}: {2}' -f $_.Exception.Response.StatusCode.value__,$_.Exception.Response.StatusDescription,($ErrorMessage,$_.ErrorDetails.Message -ne $null)[0])
        if ($AsBoolean) {
            $false
        } else {
            $message = $_.ErrorDetails.Message | ConvertFrom-json | Select-Object -expandproperty message
            $ErrorOutput = '"{0} {1}: {2}' -f $_.Exception.Response.StatusCode.value__,$_.Exception.Response.StatusDescription,($message,$ErrorMessage -ne $null)[0] 
            Write-Error $ErrorOutput
            #throw ('"{0} {1}: {2}' -f $_.Exception.Response.StatusCode.value__,$_.Exception.Response.StatusDescription,($message,$ErrorMessage -ne $null)[0])
        } 
    }
}
