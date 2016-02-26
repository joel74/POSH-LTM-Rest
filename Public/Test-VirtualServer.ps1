Function Test-VirtualServer { 
<#
.SYNOPSIS
    Test whether the specified virtual server exists
.NOTES
    Virtual server names are case-specific.
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,
        [Alias("VirtualServerName")]
	[Parameter(Mandatory=$true)]
	[string]$Name
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    Write-Verbose "NB: Virtual server names are case-specific."

    #Build the URI for this virtual server
    $URI = $F5session.BaseURL + 'virtual/{0}' -f ($Name -replace '/','~')

    Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5session.Credential -AsBoolean
}
