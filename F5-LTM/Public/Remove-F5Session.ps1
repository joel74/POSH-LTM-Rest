Function Remove-F5Session {
<#
.SYNOPSIS
    Remove F5 session based on the token
#>
    [cmdletBinding()]
    param (
        $F5Session = $Script:F5Session,
        [switch]$SkipCertificateCheck
    )
    #Validate F5Session
    Test-F5Session($F5Session)

    try {

        if ($SkipCertificateCheck) {

            if ($PSVersionTable.PSVersion.Major -ge 6) {

                $RemoveSession = Invoke-RestMethod "https://$($F5Session.name)/mgmt/shared/authz/tokens/$($F5Session.token)" -Headers @{'X-F5-Auth-Token' = $F5Session.token } -Method DELETE -SkipCertificateCheck -ErrorVariable LTMError
            }
            else {

                [SSLValidator]::OverrideValidation()
                $RemoveSession = Invoke-RestMethod "https://$($F5Session.name)/mgmt/shared/authz/tokens/$($F5Session.token)" -Headers @{'X-F5-Auth-Token' = $F5Session.token } -Method DELETE -ErrorVariable LTMError
                [SSLValidator]::RestoreValidation()
            }
        }
        else {

            $RemoveSession = Invoke-RestMethod "https://$($F5Session.name)/mgmt/shared/authz/tokens/$($F5Session.token)" -Headers @{'X-F5-Auth-Token' = $F5Session.token } -Method DELETE -ErrorVariable LTMError
        }

        Write-Verbose "Session : token $($RemoveSession.token) deleted"
        Remove-Variable F5Session -Scope Script
        Return($true)
    }

    catch {

        $ErrorMessage = $LTMError[0].message;
        Throw ("We failed to remove the specified session. The error was: $ErrorMessage")

    }
}