Function Disable-PoolMember {
<#
.SYNOPSIS
    Disable a pool member in the specified pools
    If no pool is specified, the member will be disabled in all pools
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias('PoolMember')]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName,
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,

        [PoshLTM.F5Address]$Address=[PoshLTM.F5Address]::Any,

        [Parameter(Mandatory=$false)]
        [string]$Name='*',

        [switch]$Force
    )
    begin {
        #If the -Force param is specified pool members do not accept any new connections, even if they match an existing persistence session.
        #Otherwise, members will only accept new connections that match an existing persistence session.
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                switch ($InputObject.kind) {
                    "tm:ltm:pool:poolstate" {
                        if ($Address -eq [PoshLTM.F5Address]::Any) {
                            Write-Error 'Address is required when the pipeline object is not a PoolMember'
                        } else {
                            $InputObject | Get-PoolMember -F5session $F5Session -Address $Address -Name $Name | Disable-PoolMember -F5session $F5Session -Force:$Force
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
                            $URI = $F5Session.GetLink($member.selfLink)
                            Invoke-F5RestMethod -Method PATCH -Uri "$URI" -F5Session $F5Session -Body $JSONBody -ErrorMessage "Failed to disable $Address in the $PoolName pool." -AsBoolean
                        }
                    }
                }
            }
            PoolName {
                Get-PoolMember -F5session $F5Session -PoolName $PoolName -Partition $Partition -Address $Address -Name $Name | Disable-PoolMember -F5session $F5Session -Force:$Force
            }
        }
    }
}