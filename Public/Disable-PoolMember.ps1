Function Disable-PoolMember{
<#
.SYNOPSIS
    Disable a pool member in the specified pools
    If no pool is specified, the member will be disabled in all pools
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$false)]$PoolName=$null,
        [Parameter(Mandatory=$false)][switch]$Force
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    #If the -Force param is specified pool members do not accept any new connections, even if they match an existing persistence session.
    #Otherwise, members will only accept only new connections that match an existing persistence session.
    If ($Force){
        $AcceptNewConnections = "user-down"
    }
    Else {
        $AcceptNewConnections = "user-up"
    }

    $JSONBody = @{state=$AcceptNewConnections;session='user-disabled'} | ConvertTo-Json

    #If a pool name is passed in, verify the pool exists and disable the member in that pool only
    If ($PoolName){

        If (Test-Pool -F5session $F5session -PoolName $PoolName){

            $MemberFullName = (Get-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolName).Name

            $Partition = 'Common'
            if ($PoolName -match '^[/\\](?<Partition>[^/\\]*)[/\\](?<Name>[^/\\]*)$') {
                $Partition = $matches['Partition']
                $PoolName = $matches['Name']
            }

            $URI = $F5session.BaseURL + "pool/~$Partition~$PoolName/members/$MemberFullName"

            Try {
                $response = Invoke-RestMethodOverride -Method Put -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody
                $true
            }
            Catch {
                Write-Error "Failed to disable $ComputerName in the $PoolName pool."
                Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
                Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
            }
        }
        Else {
            Write-Verbose "Pool $PoolName not found"
            Return($false)
        }
    }

    #Otherwise, disable the member in all their pools
    Else {

        $Pools = Get-PoolsForMember -ComputerName $ComputerName -F5session $F5session

        ForEach ($PoolFullName in $Pools){

            $MemberFullName = (Get-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolFullName).FullPath

            $URI = $F5session.BaseURL + ('pool/{0}/members/{1}' -f ($PoolFullName -replace '[/\\]','~'),($MemberFullName -replace '[/\\]','~'))

            Try {
                $response = Invoke-RestMethodOverride -Method Put -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody
            }
            Catch {
                Write-Error "Failed to disable $ComputerName in the $PoolName pool."
                Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
                Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
                Return($false)
            }

        }
        $true
    }    
}
