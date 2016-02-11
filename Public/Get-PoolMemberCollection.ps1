﻿Function Get-PoolMemberCollection {
<#
.SYNOPSIS
    Get the members of the specified pool
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$PoolName
    )

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
