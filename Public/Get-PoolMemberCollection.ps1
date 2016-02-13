Function Get-PoolMemberCollection {
<#
.SYNOPSIS
    Get the members of the specified pool
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$PoolName
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $PoolMembersPage = $F5session.BaseURL + 'pool/{0}/members/?' -f ($PoolName -replace '[/\\]','~')

    Try {
        $PoolMembersJSON = Invoke-RestMethodOverride -Method Get -Uri $PoolMembersPage -Credential $F5session.Credential
        $PoolMembersJSON.items
    }
    Catch {
        Write-Error "Failed to get the members of the $PoolName pool."
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

}
