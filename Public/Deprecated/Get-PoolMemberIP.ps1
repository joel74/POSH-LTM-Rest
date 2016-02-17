Function Get-PoolMemberIP {
<#
.SYNOPSIS
    Get-PoolMemberIP is deprecated.  Please use Get-PoolMember | Select-Object -ExpandProperty address
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName
    )
    Write-Warning "Get-PoolMemberIP is deprecated.  Please use Get-PoolMember | Select-Object -ExpandProperty address"
    Get-PoolMember -F5Session $F5Session -Address $ComputerName -PoolName $PoolName | Select-Object -ExpandProperty address
}