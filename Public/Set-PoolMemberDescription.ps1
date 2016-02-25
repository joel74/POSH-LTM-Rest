Function Set-PoolMemberDescription {
<#
.SYNOPSIS
    Set the description value for the specified pool member
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
        [Parameter(Mandatory=$false,ParameterSetName='InputObject')]
        [Parameter(Mandatory=$true,ParameterSetName='PoolName')]
        [string]$Address='*',

        [string]$Name='*',
        
        [Parameter(Mandatory=$true)]$Description
    )
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                switch ($InputObject.kind) {
                    "tm:ltm:pool:poolstate" {
                        if (!$Address) {
                            Write-Error 'Address is required when the pipeline object is not a PoolMember'
                        } else {
                            $InputObject | Get-PoolMember -F5session $F5session -Address $Address -Name $Name | Set-PoolMemberDescription -F5session $F5Session
                        }
                    }
                    "tm:ltm:pool:members:membersstate" {
                        foreach($member in $InputObject) {
                            $JSONBody = @{description=$Description} | ConvertTo-Json
                            $URI = $F5session.GetLink($member.selfLink)
                            Invoke-RestMethodOverride -Method PUT -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to set the description on $ComputerName in the $PoolName pool to $Description." -AsBoolean
                        }
                    }
                }
            }
            PoolName {
                Get-PoolMember -F5session $F5session -PoolName $PoolName -Partition $Partition -Address $Address -Name $Name | Set-PoolMemberDescription -F5session $F5session -Description $Description
            }
        }
    }
}
