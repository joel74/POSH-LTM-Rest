Function Test-VirtualServer { 
<#
.SYNOPSIS
    Test whether the specified virtual server exists
.NOTES
    Pool names are case-specific.
#>
    param (
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)][string]$VirtualServerName
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    Write-Verbose "NB: Virtual server names are case-specific."

    #Build the URI for this virtual server
    $URI = $F5session.BaseURL + 'virtual/{0}' -f ($VirtualServerName -replace '[/\\]','~')

    Try {
        Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5session.Credential | out-null
        $true
    }
    Catch{
        $false
    }

}
