Function Enable-PoolMember {
<#
.SYNOPSIS
    Enable a pool member in the specified pools
    If no pool is specified, the member will be disabled in all pools
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$false)]$PoolName=$null
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $JSONBody = @{state='user-up';session='user-enabled'} | ConvertTo-Json

    #If a pool name is passed in, verify the pool exists and enable the member in that pool only
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
                Write-Error "Failed to enable $ComputerName in the $PoolName pool."
                Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
                Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
            }
        }

        Else {
            Write-Verbose "Pool $PoolName not found"
            Return($false)
        }

    }

    #Otherwise, enable the member in all their pools
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
