Function Test-HealthMonitor {
<#
.SYNOPSIS
    Test whether the specified health monitor exists
.NOTES
    HealthMonitor names are case-specific.
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Type        
    )
    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    Write-Verbose "NB: HealthMonitor names are case-specific."

    #Build the URI for this health monitor
    $URI = $F5session.BaseURL + 'monitor/{0}/{1}' -f $Type,($Name -replace '/','~')

    Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5session.Credential -ErrorAction SilentlyContinue -AsBoolean
}
