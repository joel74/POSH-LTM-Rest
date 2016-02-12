Function Remove-VirtualServer{
<#
.SYNOPSIS
    Remove the specified virtual server. Confirmation is needed.
.NOTES
    Virtual server names are case-specific.
#>
    [CmdletBinding( SupportsShouldProcess=$true, ConfirmImpact="High")]    

    param (
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)][string]$VirtualServerName

    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    Write-Verbose "NB: Virtual server names are case-specific."

    #Build the URI for this pool
    $URI = $F5session.BaseURL + 'virtual/{0}' -f ($VirtualServerName -replace '[/\\]','~')

    if ($pscmdlet.ShouldProcess($VirtualServerName)){

        #Check whether the specified virtual server exists
        If (!(Test-VirtualServer -F5session $F5session -VirtualServerName $VirtualServerName)){
            Write-Error "The $VirtualServerName virtual server does not exist."
        }

        Else {

            Try {
                $response = Invoke-RestMethodOverride -Method DELETE -Uri "$URI" -Credential $F5session.Credential -ContentType 'application/json'
                Write-Output $true
            }
            Catch {
                Write-Error ("Failed to remove the $VirtualServerName virtual server.")
                Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
                Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)            
            }
        }
    }

}
