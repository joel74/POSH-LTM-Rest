Function Set-PoolMemberRatio {
<#
.SYNOPSIS
    Set the ratio value for the specified pool member
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

        [Parameter(Mandatory=$false,ParameterSetName='InputObject')]
        [Parameter(Mandatory=$true,ParameterSetName='PoolName')]
        [PoshLTM.F5Address]$Address=[PoshLTM.F5Address]::Any,

        [string]$Name='*',

        [Parameter(Mandatory=$true)]$Ratio
    )
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                switch ($InputObject.kind) {
                    "tm:ltm:pool:poolstate" {
                        if ($Address -eq [PoshLTM.F5Address]::Any) {
                            Write-Error 'Address is required when the pipeline object is not a PoolMember'
                        } else {
                            $InputObject | Get-PoolMember -F5session $F5Session -Address $Address -Name $Name | Set-PoolMemberRatio -F5session $F5Session
                        }
                    }
                    "tm:ltm:pool:members:membersstate" {
                        foreach($member in $InputObject) {
                            $JSONBody = @{ratio=$Ratio} | ConvertTo-Json
                            $URI = $F5Session.GetLink($member.selfLink)
                            Invoke-F5RestMethod -Method PATCH -Uri "$URI" -F5Session $F5Session -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to set the ratio on $($member.Name) in the $PoolName pool to $Ratio."
                        }
                    }
                }
            }
            PoolName {
                Get-PoolMember -F5session $F5Session -PoolName $PoolName -Partition $Partition -Address $Address -Name $Name | Set-PoolMemberRatio -F5session $F5Session -Ratio $Ratio
            }
        }
    }
}
