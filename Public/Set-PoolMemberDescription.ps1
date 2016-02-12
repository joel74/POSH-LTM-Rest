Function Set-PoolMemberDescription {
<#
.SYNOPSIS
    Set the description value for the specified pool member
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName,
        [Parameter(Mandatory=$true)]$Description
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $IPAddress = Get-PoolMemberIP -ComputerName $ComputerName -PoolName $PoolName -F5Session $F5session

    $Partition = 'Common'
    if ($PoolName -match '^[/\\](?<Partition>[^/\\]*)[/\\](?<Name>[^/\\]*)$') {
        $Partition = $matches['Partition']
        $PoolName = $matches['Name']
    }

    $URI = $F5session.BaseURL + "pool/~$Partition~$PoolName/members/~$Partition~$IPAddress"

    $JSONBody = @{description=$Description} | ConvertTo-Json

    Try {
        $response = Invoke-RestMethodOverride -Method PUT -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody -ContentType 'application/json'
        $true
    }
    Catch {
        Write-Error "Failed to set the description on $ComputerName in the $PoolName pool to $Description."
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

}
