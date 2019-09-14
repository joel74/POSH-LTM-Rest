Function Test-F5Session {
<#
.SYNOPSIS
    Check that the F5Session object has a valid base URL and PSCredential object
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session
    )
    #Validate F5Session 
    If ($($F5Session.BaseURL) -ne ("https://$($F5Session.Name)/mgmt/tm/ltm/") -or ($F5Session.WebSession.GetType().name -ne 'WebRequestSession')) { 
        Write-Error 'You must either create an F5 Session with script scope (by calling New-F5Session with -passthrough parameter) or pass an F5 session to this function.' 
    }
# JN: Currently this function returns nothing if successful, which doesn't seem correct. However, if it returned true, all functions that call it would need to suppress the returned value
#    Else {
#        Return($true)
#    }
}