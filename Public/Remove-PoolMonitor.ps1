Function Remove-PoolMonitor {
<#
.SYNOPSIS
    Removes a health monitor from a pool 
#>
    [cmdletBinding( SupportsShouldProcess=$true, ConfirmImpact="Low")]  
    param(
        [Parameter(Mandatory=$true)]
        $F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias('Pool')]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName,
        [Parameter(Mandatory=$false,ParameterSetName='PoolName')]
        [string]$Partition,

        [Parameter(Mandatory=$true)]
        [string[]]$Name
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Health monitor names are case-specific."
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                foreach($pool in $InputObject) {
                    if ($pscmdlet.ShouldProcess($pool.fullPath)){

                        $monitor = ($pool.monitor -split ' and ' | Where-Object { $_.Trim() -ne $Name }) -join ' and '
                        $JSONBody = @{monitor=$monitor} | ConvertTo-Json
                        $URI = $F5Session.GetLink($pool.selfLink)
                        Invoke-RestMethodOverride -Method PUT -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ContentType 'application/json'
                    }
                }
            }
            PoolName {
                Get-Pool -F5session $F5Session -PoolName $PoolName -Partition $Partition | Remove-PoolMonitor -F5session $F5Session -Name $Name
            }
        }
    }
}
