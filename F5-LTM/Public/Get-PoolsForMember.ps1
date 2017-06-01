Function Get-PoolsForMember {
<#
.SYNOPSIS
    Determine which pool(s) a server is in
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias('PoolMember')]
        [PSObject]$InputObject,

        [Parameter(Mandatory=$false,ParameterSetName='Address')]
        [PoshLTM.F5Address[]]$Address=[PoshLTM.F5Address]::Any
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            Address {
                $pools = Get-Pool -F5Session $F5Session
                foreach ($pool in $pools) {
                    $members = $pool | Get-PoolMember -F5session $F5Session | Where-Object { [PoshLTM.F5Address]::IsMatch($Address, $_.address) }
                    if ($members) {
                        $pool
                    }
                }
            }
            InputObject {
                foreach($member in $InputObject) {
                    Get-PoolsForMember -F5Session $F5Session -Address $member.address
                }
            }
        }
    }
}
