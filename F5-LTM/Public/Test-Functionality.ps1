Function Test-Functionality{
<#
.SYNOPSIS
    Perform some standard tests to make sure things work as expected
.EXAMPLE
    Test-Functionality -F5Session $F5session -TestVirtualServer 'virt123' -TestVirtualServerIP '10.1.1.240' -TestPool 'testpool123' -PoolMember 'Server1'
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    param (
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$TestVirtualServer,
        [Parameter(Mandatory=$true)]$TestVirtualServerIP,
        [Parameter(Mandatory=$true)]$TestPool,
        [Parameter(Mandatory=$true)]$PoolMember
    )

    $TestNotesColor = 'Cyan'

    Write-Host "-----`r`nBeginning test`r`n-----" -ForegroundColor $TestNotesColor

    Write-Host "* Get the failover status of the F5 device" -ForegroundColor $TestNotesColor
    Get-F5Status -F5Session $F5Session

    Write-Host "`r`n* Get a list of all pools" -ForegroundColor $TestNotesColor
    $pools = Get-PoolList -F5Session $F5Session
    $pools

    Write-Host ("`r`n* Test whether the first pool in the list - " + $pools[0] + " - exists") -ForegroundColor $TestNotesColor
    Test-Pool -F5Session $F5Session -PoolName $pools[0]

    Write-Host ("`r`n* Get the pool " + $pools[0]) -ForegroundColor $TestNotesColor
    Get-Pool -F5Session $F5Session -PoolName $pools[0]

    Write-Host ("`r`n* Get members of the pool '" + $pools[0] + "'") -ForegroundColor $TestNotesColor
    Get-PoolMemberCollection -F5Session $F5Session -PoolName $pools[0]

    Write-Host ("`r`n* Get the status of all members in the " + $pools[0] + " pool") -ForegroundColor $TestNotesColor
    Get-PoolMemberCollectionStatus -F5Session $F5Session -PoolName $pools[0]

    Write-Host "`r`n* Create a new pool named '$TestPool'" -ForegroundColor $TestNotesColor
    New-Pool -F5Session $F5Session -PoolName $TestPool 

    Write-Host "`r`n* Add the computer $PoolMember to the pool '$TestPool'" -ForegroundColor $TestNotesColor
    Add-PoolMember -F5Session $F5Session -ComputerName $PoolMember -PortNumber 80 -PoolName $TestPool -Status Enabled

    Write-Host "`r`n* Get the new pool member" -ForegroundColor $TestNotesColor
    Get-PoolMember -F5Session $F5Session -ComputerName $PoolMember -PoolName $TestPool

    Write-Host "`r`n* Get the IP address for the new pool member" -ForegroundColor $TestNotesColor
    Get-PoolMemberIP -F5Session $F5Session -ComputerName $PoolMember -PoolName $TestPool

    Write-Host "`r`n* Get all pools of which this pool member is a member" -ForegroundColor $TestNotesColor
    Get-PoolsForMember -F5Session $F5Session -ComputerName $PoolMember

    Write-Host "`r`n* Get the number of current connections for this pool member" -ForegroundColor $TestNotesColor
    Get-CurrentConnectionCount -F5Session $F5Session -ComputerName $PoolMember -PoolName $TestPool

    Write-Host "`r`n* Disable the new pool member" -ForegroundColor $TestNotesColor
    Disable-PoolMember -F5Session $F5Session -ComputerName $PoolMember -PoolName $TestPool

    Write-Host "`r`n* Get the status of the new pool member" -ForegroundColor $TestNotesColor
    $PoolMemberStatus = Get-PoolMemberStatus -F5Session $F5Session -ComputerName $PoolMember -PoolName $TestPool
    $PoolMemberStatus

    Write-Host "`r`n* Set the pool member description to 'My new pool' and retrieve it" -ForegroundColor $TestNotesColor
    Write-Host "Old description:"
    Get-PoolMemberDescription -F5Session $F5Session -ComputerName $PoolMember -PoolName $TestPool
    Set-PoolMemberDescription -F5Session $F5Session -ComputerName $PoolMember -PoolName $TestPool -Description 'My new pool' | out-null
    Write-Host "New description:"
    Get-PoolMemberDescription -F5Session $F5Session -ComputerName $PoolMember -PoolName $TestPool

    Write-Host "`r`n* Enable the new pool member" -ForegroundColor $TestNotesColor
    Enable-PoolMember -F5Session $F5Session -ComputerName $PoolMember -PoolName $TestPool

    Write-Host "`r`n* Remove the new pool member from the pool" -ForegroundColor $TestNotesColor
    Remove-PoolMember -F5Session $F5Session -ComputerName $PoolMember -PortNumber 80 -PoolName $TestPool

    Write-Host "`r`n* Get a list of all virtual servers" -ForegroundColor $TestNotesColor
    $virtualServers = Get-VirtualServerList -F5Session $F5Session
    $virtualServers

    Write-Host ("`r`n* Test whether the first virtual server in the list - " +  $virtualServers[0] + " - exists") -ForegroundColor $TestNotesColor
    Test-VirtualServer -F5Session $F5Session -VirtualServerName $virtualServers[0]

    Write-Host ("`r`n* Get the virtual server '" + $virtualServers[0] + "'") -ForegroundColor $TestNotesColor
    Get-VirtualServer -F5Session $F5Session -VirtualServerName $virtualServers[0]

    Write-Host "`r`n* Create a new virtual server named '$TestVirtualServer'" -ForegroundColor $TestNotesColor
    New-VirtualServer -F5Session $F5Session -VirtualServerName $TestVirtualServer -Description 'description' -DestinationIP $TestVirtualServerIP -DestinationPort '80' -DefaultPool $TestPool -IPProtocol 'tcp' -ProfileNames 'http'

    Write-Host ("`r`n* Retrieve all iRules on the F5 LTM device.") -ForegroundColor $TestNotesColor
    $iRules = Get-iRuleCollection -F5Session $F5Session
    Write-Output ("- This can be a large collection. The first entry found is:")
    Write-Output $iRules[0]

    Write-Host ("`r`n* Add the iRule '" + $iRules[0].fullPath + "' to the new virtual server '$TestVirtualServer'") -ForegroundColor $TestNotesColor
    Add-iRuleToVirtualServer -F5Session $F5Session -VirtualServer $TestVirtualServer -iRuleName $($iRules[0].fullPath)

    Write-Host "`r`n* Get all iRules assigned to '$TestVirtualServer'" -ForegroundColor $TestNotesColor
    Get-VirtualServeriRuleCollection -F5Session $F5Session -VirtualServer $TestVirtualServer 

    Write-Host ("`r`n* Remove the '" + $iRules[0].name + "' iRule from the new virtual server '$TestVirtualServer'") -ForegroundColor $TestNotesColor
    Remove-iRuleFromVirtualServer -F5Session $F5Session -VirtualServer $TestVirtualServer -iRuleName $iRules[0].name

    Write-Host "`r`n* Remove the new virtual server '$TestVirtualServer'" -ForegroundColor $TestNotesColor
    Write-Host "(This will raise a confirmation prompt unless -confirm is set to false)" -ForegroundColor $TestNotesColor
    Remove-VirtualServer -F5Session $F5Session -VirtualServerName $TestVirtualServer

    Write-Host "`r`n* Remove the new pool '$TestPool'" -ForegroundColor $TestNotesColor
    Write-Host "(This will raise a confirmation prompt unless -confirm is set to false)" -ForegroundColor $TestNotesColor
    Remove-Pool -F5Session $F5Session -PoolName $TestPool

    Write-Host "-----`r`nTest complete`r`n-----" -ForegroundColor $TestNotesColor

}