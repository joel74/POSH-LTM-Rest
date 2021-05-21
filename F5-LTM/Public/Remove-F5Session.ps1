Function Remove-F5Session {
    <#
    .SYNOPSIS
        Remove F5 session based on the token
    #>
    [cmdletBinding()]
    param (
        $F5Session = $Script:F5Session,
        [switch]$SkipCertifcateCheck
    )
    #Validate F5Session 
    Test-F5Session($F5Session)
    
    if ($SkipCertifcateCheck) {

        if ($PSVersionTable.PSVersion.Major -ge 6) {

            $RemoveSession = Invoke-RestMethod "https://$($F5Session.name)/mgmt/shared/authz/tokens/$($F5Session.token)" -Headers @{'X-F5-Auth-Token' = $F5Session.token } -Method DELETE -SkipCertificateCheck
        }
        else {

            add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
            $RemoveSession = Invoke-RestMethod "https://$($F5Session.name)/mgmt/shared/authz/tokens/$($F5Session.token)" -Headers @{'X-F5-Auth-Token' = $F5Session.token } -Method DELETE
        }
    }
    else {

        $RemoveSession = Invoke-RestMethod "https://$($F5Session.name)/mgmt/shared/authz/tokens/$($F5Session.token)" -Headers @{'X-F5-Auth-Token' = $F5Session.token } -Method DELETE
    }

    Write-Verbose "Session : token $($RemoveSession.token) deleted"
}