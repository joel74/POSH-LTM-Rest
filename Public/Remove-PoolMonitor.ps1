Function Remove-PoolMonitor {
<#
.SYNOPSIS
    Remove health monitor(s) from a pool 
.NOTES
    Health monitor names are case-specific.
#>
    [cmdletBinding( SupportsShouldProcess=$true, ConfirmImpact="Low")]  
    param(
        $F5Session=$Script:F5Session,

        [Alias('Pool')]
        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipelineByPropertyName=$true)]
        [string[]]$PoolName,
        [Parameter(Mandatory=$false,ParameterSetName='PoolName',ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
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
                        $monitor = ($pool.monitor -split ' and ' | Where-Object { $Name -notcontains $_.Trim() }) -join ' and '
                        $JSONBody = @{monitor=$monitor} | ConvertTo-Json
                        $URI = $F5Session.GetLink($pool.selfLink)
                        Invoke-RestMethodOverride -Method PATCH -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ContentType 'application/json'
                    }
                }
            }
            PoolName {
                Get-Pool -F5session $F5Session -Name $PoolName -Partition $Partition | Remove-PoolMonitor -F5session $F5Session -Name $Name
            }
        }
    }
}
