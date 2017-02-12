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

    $ProfileURL = $F5Session.BaseURL +$ProfileName

    Invoke-F5RestMethod -Method DELETE -Uri "$ProfileURL" -F5Session $F5Session -ErrorMessage "Failed to clear the ram cache for the $ProfileName profile." |
        Out-Null
}
