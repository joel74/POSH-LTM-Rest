Function Get-F5Status{
<#
.SYNOPSIS                                                                          
    Test whether the specified F5 is currently in active or standby failover mode
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $FailoverPage = $F5Session.BaseURL -replace "/ltm/", "/cm/failover-status"

    $FailoverJSON = Invoke-F5RestMethod -Method Get -Uri $FailoverPage -F5Session $F5Session

    #This is where the failover status is indicated
    $FailoverJSON.entries.'https://localhost/mgmt/tm/cm/failover-status/0'.nestedStats.entries.status.description
}
