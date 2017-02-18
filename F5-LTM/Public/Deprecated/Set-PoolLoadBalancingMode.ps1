Function Set-PoolLoadBalancingMode {
<#
.SYNOPSIS
    Set-PoolLoadBalancingMode is deprecated.  Please use Set-Pool
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias('Pool')]
        [PSObject[]]$InputObject,
        
        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName,

        [Parameter(Mandatory=$false,ParameterSetName='PoolName')]
        [string]$Partition,
        
        [Alias('LoadBalancingMode')]
        [Parameter(Mandatory=$true)]
        [ValidateSet("dynamic-ratio-member","dynamic-ratio-node","fastest-app-response","fastest-node","least-connections-members","least-connections-node","least-sessions","observed-member","observed-node","predictive-member","predictive-node","ratio-least-connections-member","ratio-least-connections-node","ratio-member","ratio-node","ratio-session","round-robin","weighted-least-connections-member","weighted-least-connections-node")]
        [string]$Name
    )
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                $InputObject | Set-Pool -F5Session $F5Session -LoadBalancingMode $Name
            }
            PoolName {
                Get-Pool -F5Session $F5Session -Name $PoolName -Partition $Partition  | Set-Pool -F5Session $F5Session -LoadBalancingMode $Name
            }
        }
    }
}