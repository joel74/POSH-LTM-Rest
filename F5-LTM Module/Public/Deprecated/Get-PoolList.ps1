Function Get-PoolList {
<#
.SYNOPSIS
    Get-PoolList is deprecated.  Please use Get-Pool | Select-Object -ExpandProperty fullPath
#>
    param (
        $F5Session=$Script:F5Session
    )
    Write-Warning "Get-PoolList is deprecated.  Please use Get-Pool | Select-Object -ExpandProperty fullPath"
    Get-Pool -F5Session $F5Session | Select-Object -ExpandProperty fullPath
}