Function Get-PoolMember {
<#
.SYNOPSIS
    Get details about the specified pool member
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $PoolMember = $null

    $IPAddress = Get-PoolMemberIP -F5Session $F5session -ComputerName $ComputerName -PoolName $PoolName

    $Partition = 'Common'
    if ($PoolName -match '^[/\\](?<Partition>[^/\\]*)[/\\](?<Name>[^/\\]*)$') {
        $Partition = $matches['Partition']
        $PoolName = $matches['Name']
    }

    $PoolMemberURI = $F5session.BaseURL + "pool/~$Partition~$PoolName/members/~$Partition~$IPAddress`?"

    Try {
        $PoolMemberJSON = Invoke-RestMethodOverride -Method Get -Uri $PoolMemberURI -Credential $F5session.Credential
        $PoolMemberJSON
    }
    Catch {
        Write-Error "Failed to get the details for the pool member $ComputerName in the $PoolName pool."
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

    $PoolMember

}
