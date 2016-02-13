Function Get-VirtualServerList{
<#
.SYNOPSIS
    Get a list of all virtual servers for the specified F5 LTM
#>

    param (
        $F5Session=$Script:F5Session
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    #Only retrieve the pool names
    $VirtualServersPage = $F5session.BaseURL + 'virtual?$select=fullPath'

    Try {
        $VirtualServersJSON = Invoke-RestMethodOverride -Method Get -Uri $VirtualServersPage -Credential $F5session.Credential
        $VirtualServersJSON.items.fullPath

    }
    Catch{

        Write-Error ("Failed to retrieve the list of virtual servers.")
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

}
