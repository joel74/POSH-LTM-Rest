Function Get-PoolsForMember {
<#
.SYNOPSIS
    Determine which pool(s) a server is in
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$ComputerName
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    #All servers that are LTM pool members use the NIC with a default gateway as the IP that registers with the LTM
    $ComputerIP = Get-CimInstance -ComputerName $ComputerName -Class Win32_NetworkAdapterConfiguration | Where-Object DefaultIPGateway | Select-Object -exp IPaddress | Select-Object -first 1

    $AllPools = Get-PoolList -F5session $F5session

    $PoolsFound = @()

    foreach($Pool in $AllPools) 
    {
        $PoolMembers = Get-PoolMemberCollection -PoolName $Pool -F5session $F5session

        foreach($PoolMember in $PoolMembers) {

            if($PoolMember.address -eq $ComputerIP) {
                $PoolsFound += $Pool
            }
        }

    }

    $PoolsFound
}
