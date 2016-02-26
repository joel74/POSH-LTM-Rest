Function Get-HealthMonitorType {
<#
.SYNOPSIS
    Get a list of all health monitor types for the specified F5 LTM
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session        
    )
    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    #Only retrieve the Health monitor types
    $Uri = $F5session.BaseURL + "monitor/"

    $monitors = Invoke-RestMethodOverride -Method Get -Uri $Uri -Credential $F5session.Credential -ErrorMessage "Failed to get the list of healt monitor types."
    $monitors.items.reference | ForEach-Object { [Regex]::Match($_.Link,'(?<=/)[^/?]*(?=\?)').Value }
}
