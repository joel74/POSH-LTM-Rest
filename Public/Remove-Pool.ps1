﻿Function Remove-Pool{
<#
.SYNOPSIS
    Remove the specified pool. Confirmation is needed
.NOTES
    Pool names are case-specific.
#>

    [CmdletBinding( SupportsShouldProcess=$true, ConfirmImpact="High")]    

    param (
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)][string]$PoolName

    )

    #Build the URI for this pool
    $URI = $F5session.BaseURL + 'pool/{0}' -f ($PoolName -replace '[/\\]','~')

    if ($pscmdlet.ShouldProcess($PoolName)){

        #Check whether the specified pool already exists
        If (!(Test-Pool -F5session $F5session -PoolName $PoolName)){
            Write-Error "The $PoolName pool does not exist.`r`nNB: Pool names are case-specific."
        }

        Else {

            Try {
                $response = Invoke-RestMethodOverride -Method DELETE -Uri "$URI" -Credential $F5session.Credential -ContentType 'application/json'
                Write-Output $true
            }
            Catch {
                Write-Error "Failed to remove the $PoolName pool."
                Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
                Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
                Return($false)
            }

        }
    }

}
