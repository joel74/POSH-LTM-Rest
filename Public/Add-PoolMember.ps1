Function Add-PoolMember{
<#
.SYNOPSIS
    Add a computer to a pool as a member
.LINK
[Modifying pool members](https://devcentral.f5.com/questions/modifying-pool-members-through-rest-api)
[Add a pool with an existing node member](https://devcentral.f5.com/questions/add-a-new-pool-with-an-existing-node)
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PortNumber,
        [Parameter(Mandatory=$true)]$PoolName,
        [ValidateSet("Enabled","Disabled")]
        [Parameter(Mandatory=$true)]$Status
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $IPAddress = Get-CimInstance -ComputerName $ComputerName -Class Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue | Where-Object DefaultIPGateway | Select-Object -exp IPaddress | Select-Object -first 1
    #If we don't get an IP address for the computer, then fail
    If (!($IPAddress)){
        Write-Error "Failed to obtain IP address for $ComputerName. The error returned was:`r`n$Error[0]"
        Return($false)
    }

    $MemberName = $IPAddress + ":" + $PortNumber
    #$MemberName = $ComputerName + ":" + $PortNumber # My existing members are computername:port

    $Partition = 'Common'
    if ($PoolName -match '^[/\\](?<Partition>[^/\\]*)[/\\](?<Name>[^/\\]*)$') {
        $Partition = $matches['Partition']
    }

    $JSONBody = @{name=$MemberName;partition=$Partition;address=$IPAddress;description=$ComputerName} | ConvertTo-Json

    $URI = $F5session.BaseURL + 'pool/{0}/members' -f ($PoolName -replace '[/\\]','~')

    Try {
        Invoke-RestMethodOverride -Method POST -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorAction SilentlyContinue
    }
    Catch {
        Write-Error "Failed to add $ComputerName to $PoolName."
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

    #After adding to the pool, make sure the member status is set as specified
    If ($Status -eq "Enabled"){
        Enable-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolName 
    }
    ElseIf ($Status -eq "Disabled"){
        Disable-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolName 
    }
}
