Function Disable-PoolMember {
<#
.SYNOPSIS
    Disable a pool member in the specified pools
    If no pool is specified, the member will be disabled in all pools
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

        [Parameter(Mandatory=$false)]
        [string]$Name='*',
        
        [switch]$Force
    )
    begin {
        #If the -Force param is specified pool members do not accept any new connections, even if they match an existing persistence session.
        #Otherwise, members will only accept only new connections that match an existing persistence session.
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                switch ($InputObject.kind) {
                    "tm:ltm:pool:poolstate" {
                        if (!$Address) {
                            Write-Error 'Address is required when the pipeline object is not a PoolMember'
                        } else {
                            $InputObject | Get-PoolMember -F5session $F5session -Address $Address -Name $Name | Disable-PoolMember -F5session $f5
                        }
                    }
                    "tm:ltm:pool:members:membersstate" {
                        If ($Force){
                            $AcceptNewConnections = "user-down"
                        }
                        Else {
                            $AcceptNewConnections = "user-up"
                        }
                        $JSONBody = @{state=$AcceptNewConnections;session='user-disabled'} | ConvertTo-Json
                        foreach($member in $InputObject) {
                            $URI = $F5session.GetLink($member.selfLink)
                            Invoke-RestMethodOverride -Method Put -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody -ErrorMessage "Failed to disable $Address in the $PoolName pool." -AsBoolean
                        }
                    }
                }
            }
            PoolName {
                Get-PoolMember -F5session $F5session -PoolName $PoolName -Partition $Partition -Address $Address -Name $Name | Disable-PoolMember -F5session $f5
            }
        }
    }
}