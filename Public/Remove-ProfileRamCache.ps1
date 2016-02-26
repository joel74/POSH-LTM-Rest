Function Remove-ProfileRamCache{
<#
.SYNOPSIS
    Delete the contents of a RAM cache for the specified profile
.NOTES
    Example profile: "profile/http/ramcache"
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$ProfileName
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $ProfileURL = $F5session.BaseURL +$ProfileName

    Invoke-RestMethodOverride -Method DELETE -Uri "$ProfileURL" -Credential $F5session.Credential -ErrorMessage "Failed to clear the ram cache for the $ProfileName profile." |
        Out-Null
}
