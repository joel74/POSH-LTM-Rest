Function Enable-PoolMember {
<#
.SYNOPSIS
    Enable a pool member in the specified pools
    If no pool is specified, the member will be enabled in all pools
#>
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias('PoolMember')]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName,
        [Parameter(Mandatory=$false,ParameterSetName='PoolName')]
        [string]$Partition,

        [Alias("ComputerName")]
        [string]$Address='*',

        [string]$Name='*'
    )
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                switch ($InputObject.kind) {
                    "tm:ltm:pool:poolstate" {
                        if (!$Address) {
                            Write-Error 'Address is required when the pipeline object is not a PoolMember'
                        } else {
                            $InputObject | Get-PoolMember -F5session $F5session -Address $Address -Name $Name | Enable-PoolMember -F5session $f5
                        }
                    }
                    "tm:ltm:pool:members:membersstate" {
                        $JSONBody = @{state='user-up';session='user-enabled'} | ConvertTo-Json
                        foreach($member in $InputObject) {
                            $URI = $F5session.GetLink($member.selfLink)
                            Invoke-RestMethodOverride -Method Put -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody -ErrorMessage "Failed to enable $Address in the $PoolName pool." -AsBoolean
                        }
                    }
                }
            }
            PoolName {
                Get-PoolMember -F5session $F5session -PoolName $PoolName -Partition $Partition -Address $Address -Name $Name | Enable-PoolMember -F5session $f5
            }
        }
    }
}