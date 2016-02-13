

Function Get-PoolList {
<#
.SYNOPSIS
    Get a list of all pools for the specified F5 LTM
#>
    param (
        $F5Session=$Script:F5Session
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    #Only retrieve the pool names
    $PoolsPage = $F5Session.BaseURL + 'pool/?$select=fullPath'

    Try {

        $PoolsJSON = Invoke-RestMethodOverride -Method Get -Uri $PoolsPage -Credential $F5session.Credential
        $PoolsJSON.items.fullPath

    }
    Catch{
        Write-Error ("Failed to get the list of pool names.")
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
 
   }
}

