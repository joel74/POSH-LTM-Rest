Function Get-VirtualServerList{
<#
.SYNOPSIS
    Get-VirtualServerList is deprecated.  Please use Get-VirtualServer | Select-Object -ExpandProperty fullPath
#>
    param (
        $F5Session=$Script:F5Session
    )
    Write-Warning "Get-VirtualServerList is deprecated.  Please use Get-VirtualServer | Select-Object -ExpandProperty fullPath"
    Get-VirtualServer -F5Session $F5Session | Select-Object -ExpandProperty fullPath
}