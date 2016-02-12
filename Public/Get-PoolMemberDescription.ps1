Function Get-PoolMemberDescription {
<#
.SYNOPSIS
    Get the current session and state values for the specified computer
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $PoolMember = Get-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolName

    $PoolMember = $PoolMember | Select-Object -Property name,description

    $PoolMember.description
}
