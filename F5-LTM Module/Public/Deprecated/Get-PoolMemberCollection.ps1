Function Get-PoolMemberCollection {
<#
.SYNOPSIS
    Get-PoolMemberCollection is deprecated.  Please use Get-PoolMember
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$PoolName
    )
    Write-Warning "Get-PoolMemberCollection is deprecated.  Please use Get-PoolMember"
    Get-PoolMember -F5Session $F5Session -PoolName $PoolName
}