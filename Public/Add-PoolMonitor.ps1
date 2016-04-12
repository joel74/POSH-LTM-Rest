Function Add-PoolMonitor {
<#
.SYNOPSIS
    Add a health monitor to a pool 
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias('Pool')]
        [PSObject[]]$InputObject,
        
        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [Alias('PoolName')]
        [string[]]$Name,

        [Parameter(Mandatory=$false,ParameterSetName='PoolName')]
        [string]$Partition,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Monitor
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                $InputObject | ForEach-Object {
                    $JSONBody = @{
                        monitor=(($($_.monitor.Trim() -split ' and ') + $Monitor | Where-Object { $_ } | Select-Object -Unique) -join ' and ')
                    } | ConvertTo-Json
                    $JSONBody
                    $URI = $F5Session.GetLink($InputObject.selfLink)
                    Invoke-RestMethodOverride -Method PUT -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ContentType 'application/json'
                }
            }
            PoolName {
                Get-Pool -F5Session $F5Session -Name $Name -Partition $Partition | Add-PoolMonitor -F5Session $F5Session -Monitor $Monitor 
            }
        }
    }
}
