Function Get-PoolMemberCollectionStatus {
<#
.SYNOPSIS
    Get the status of all members of the specified pool
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$PoolName
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $PoolMembers = Get-PoolMemberCollection -PoolName $PoolName -F5session $F5session | Select-Object -Property name,session,state

    $PoolMembers
}
