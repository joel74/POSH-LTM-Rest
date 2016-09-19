Function Test-F5Session {
<#
.SYNOPSIS
    Check that the F5Session object has a valid base URL and PSCredential object
#>
    [cmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][AllowNull()]$F5Session
    )
    #Verify the format of the BaseURL property and the existence of a WebRequestSession object.
    If ($($F5Session.BaseURL) -ne ("https://$($F5Session.Name)/mgmt/tm/ltm/") -or ($F5Session.WebSession.GetType().name -ne 'WebRequestSession')) { 
        Write-Error 'You must either create an F5 Session with script scope (by calling New-F5Session) or pass an F5 session to this function.' 
    }

    #Make a basic call using the F5 session and see if it passes
    $FailoverPage = $F5Session.BaseURL -replace "/ltm/", "/cm/failover-status"
    $FailoverJSON = Invoke-RestMethodOverride -Method Get -Uri $FailoverPage -WebSession $F5Session.WebSession

}

