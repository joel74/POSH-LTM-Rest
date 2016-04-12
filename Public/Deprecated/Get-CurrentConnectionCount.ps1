Function Get-CurrentConnectionCount {
<#
.SYNOPSIS
    Get-CurrentConnectionCount is deprecated.  Please use Get-PoolMemberStats | Select-Object -ExpandProperty 'serverside.curConns'
#>
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true)]
        [string[]]$PoolName,
        [Parameter(Mandatory=$false)]
        [string]$Partition,

        [Alias("ComputerName")]
        [Parameter(Mandatory=$false)]
        [string]$Address='*',

        [Parameter(Mandatory=$false)]
        [string]$Name='*'
    )
    Write-Warning "Get-CurrentConnectionCount is deprecated.  Please use Get-PoolMemberStats | Select-Object -ExpandProperty 'serverside.curConns'"
    Get-PoolMemberStats -F5Session $F5Session -PoolName $PoolName -Partition $Partition -Address $Address -Name $Name | Select-Object -ExpandProperty 'serverside.curConns'
}