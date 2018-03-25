Function Enable-PoolMember {
<#
.SYNOPSIS
    Enable a pool member in the specified pools
    If no pool is specified, the member will be enabled in all pools, provided that the input consists of pool member objects, and not address(es) or name(s).
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias('PoolMember')]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName,
        [Parameter(Mandatory=$false,ParameterSetName='PoolName')]
        [string]$Partition,

        [PoshLTM.F5Address]$Address=[PoshLTM.F5Address]::Any,

        [string]$Name='*'
    )
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                switch ($InputObject.kind) {
                    "tm:ltm:pool:poolstate" {
                        if ($Address -eq [PoshLTM.F5Address]::Any) {
                            Write-Error 'Address is required when the pipeline object is not a PoolMember'
                        } else {
                            $InputObject | Get-PoolMember -F5session $F5Session -Address $Address -Name $Name | Enable-PoolMember -F5session $F5Session
                        }
                    }
                    "tm:ltm:pool:members:membersstate" {
                        $JSONBody = @{state='user-up';session='user-enabled'} | ConvertTo-Json
                        foreach($member in $InputObject) {
                            $URI = $F5Session.GetLink($member.selfLink)
                            Invoke-F5RestMethod -Method PATCH -Uri "$URI" -F5Session $F5Session -Body $JSONBody -ErrorMessage "Failed to enable $Address in the $PoolName pool." -AsBoolean
                        }
                    }
                }
            }
            PoolName {
                Get-PoolMember -F5session $F5Session -PoolName $PoolName -Partition $Partition -Address $Address -Name $Name | Enable-PoolMember -F5session $F5Session
            }
        }
    }
}