Function Get-PoolMemberDescription {
<#
.SYNOPSIS
    Get-PoolMemberDescription is deprecated.  Please use Get-PoolMember | Select-Object -ExpandProperty description
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName
    )
    Write-Warning "Get-PoolMemberDescription is deprecated.  Please use Get-PoolMember | Select-Object -ExpandProperty description"
    Get-PoolMember -F5Session $F5Session -PoolName $PoolName -Address $ComputerName | Select-Object -ExpandProperty description
}