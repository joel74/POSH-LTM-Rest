Function Sync-DeviceToGroup {
<#
.SYNOPSIS
    Sync the specified device to the group. This assumes the F5 session object is for the device that will be synced to the group.
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$GroupName
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $URI = $F5Session.BaseURL -replace "/ltm", "/cm"

    $JSONBody = @{command='run';utilCmdArgs="config-sync to-group $GroupName"}
    $JSONBody = $JSONBody | ConvertTo-Json

    Invoke-RestMethodOverride -Method POST -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to sync the device to the $GroupName group" -AsBoolean
}