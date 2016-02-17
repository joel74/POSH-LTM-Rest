Function Get-PoolMemberCollectionStatus {
<#
.SYNOPSIS
    Get-PoolMemberCollectionStatus is deprecated.  Please use Get-PoolMember | Select-Object -Property name,session,state
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$PoolName
    )
    Write-Warning "Get-PoolMemberCollectionStatus is deprecated.  Please use Get-PoolMember | Select-Object -Property name,session,state"
    Get-PoolMember -F5Session $F5Session -PoolName $PoolName | Select-Object -Property name,session,state
}