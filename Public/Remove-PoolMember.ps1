Function Remove-PoolMember{
<#
.SYNOPSIS
    Remove a computer from a pool
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PortNumber,
        [Parameter(Mandatory=$true)]$PoolName
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

    $URI = $F5session.BaseURL + "pool/{0}/members/~$Partition~$MemberName" -f ($PoolName -replace '[/\\]','~')

    Try {
        $response = Invoke-RestMethodOverride -Method DELETE -Uri "$URI" -Credential $F5session.Credential -ContentType 'application/json' -ErrorAction SilentlyContinue
        $true
    }
    Catch {
        Write-Error "Failed to remove $ComputerName from $PoolName."
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

}
