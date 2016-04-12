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
        [string[]]$PoolName,

        [Parameter(Mandatory=$false,ParameterSetName='PoolName')]
        [string]$Partition,
        
        [Alias('MonitorName')]
        [Parameter(Mandatory=$true)]
        [string[]]$Name
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
                        monitor=(($($_.monitor -split ' and ') + $Name | Where-Object { $_ } | ForEach-Object { [Regex]::Match($_.Trim(), '[^/\s]*$').Value } | Select-Object -Unique) -join ' and ')
                    } | ConvertTo-Json
                    $URI = $F5Session.GetLink($InputObject.selfLink)
                    Invoke-RestMethodOverride -Method PATCH -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ContentType 'application/json'
                }
            }
            PoolName {
                Get-Pool -F5Session $F5Session -Name $PoolName -Partition $Partition | Add-PoolMonitor -F5Session $F5Session -Name $Name 
            }
        }
    }
}
