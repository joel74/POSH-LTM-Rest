Function Test-F5Session {
<#
.SYNOPSIS
    Check that the F5Session object has a valid base URL and PSCredential object
#>
    [cmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][AllowNull()]$F5Session
    )
    #Validate F5Session 
    If ($($F5Session.BaseURL) -ne ("https://$($F5Session.Name)/mgmt/tm/ltm/") -or ($F5Session.Credential.GetType().name -ne 'PSCredential')) { 
        Write-Error 'You must either create an F5 Session with script scope (by calling New-F5Session) or pass an F5 session to this function.' 
    }
}