Function Set-PoolLoadBalancingMode {
<#
.SYNOPSIS
    Sets the load balancing mode on a pool 
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
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                $JSONBody = @{loadBalancingMode=$Name} | ConvertTo-Json
                $URI = $F5Session.GetLink($InputObject.selfLink) -replace 'localhost', $F5Session.name
                Invoke-RestMethodOverride -Method PATCH -Uri "$URI" -WebSession $F5Session.WebSession -Body $JSONBody -ContentType 'application/json'
            }
            PoolName {
                Get-Pool -F5Session $F5Session -Name $PoolName -Partition $Partition | Set-PoolLoadBalancingMode -F5Session $F5Session -Name $Name
            }
        }
    }
}