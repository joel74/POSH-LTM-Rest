Function Get-PoolMemberStatus {
<#
.SYNOPSIS
    Get-PoolMemberStatus is deprecated.  Please use Get-PoolMember | Select-Object -Property name,session,state
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName
    )
    Write-Warning "Get-PoolMemberStatus is deprecated.  Please use Get-PoolMember | Select-Object -Property name,session,state"
    Get-PoolMember -F5Session $F5Session -PoolName $PoolName -Address $ComputerName | Select-Object -Property name,session,state
}