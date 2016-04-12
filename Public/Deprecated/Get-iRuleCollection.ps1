Function Get-iRuleCollection {
<#
.SYNOPSIS
    Retrieve specified iRule(s)
#>
    param(
        $F5session=$Script:F5Session
    )
    Write-Warning "Get-iRuleCollection is deprecated.  Please use Get-iRule"
    Get-iRule -F5session $F5Session
}