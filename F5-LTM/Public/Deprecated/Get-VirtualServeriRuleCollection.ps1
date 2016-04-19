Function Get-VirtualServeriRuleCollection {
<#
.SYNOPSIS
    Get-VirtualServeriRuleCollection is deprecated.  Please use Get-VirtualServer | Select-Object -ExpandProperty rules   
#>

    param (
        $F5Session=$Script:F5Session,
        [Alias("VirtualServerName")]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [string[]]$Name,
        [Parameter(Mandatory=$false)]$Partition
    )
    Write-Warning "Get-VirtualServeriRuleCollection is deprecated.  Please use Get-VirtualServer | Select-Object -ExpandProperty rules"
    Get-VirtualServer -F5Session $F5Session -Name $Name -Partition $Partition | Select-Object -ExpandProperty rules -ErrorAction SilentlyContinue
}