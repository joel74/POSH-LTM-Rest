﻿Function Sync-DeviceToGroup{
<#
.SYNOPSIS
    Sync the specified device to the group. This assumes the F5 session object is for the device that will be synced to the group.
#>
    param (
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$GroupName
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $URI = $F5session.BaseURL -replace "/ltm", "/cm"

    $JSONBody = @{command='run';utilCmdArgs="config-sync to-group $GroupName"}
    $JSONBody = $JSONBody | ConvertTo-Json

    Try{
        $response = Invoke-RestMethodOverride -Method POST -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ContentType 'application/json'
        Write-Output $true

    }
    Catch {
        Write-Error ("Failed to sync the device to the $GroupName group")
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

}
