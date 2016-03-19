Function Test-Pool {
<#
.SYNOPSIS
    Test whether the specified pool exists
.NOTES
    Pool names are case-specific.
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,
        [Alias("PoolName")]
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$false)][string]$Partition
    )
    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    Write-Verbose "NB: Pool names are case-specific."

    #Build the URI for this pool
    $URI = $F5Session.BaseURL + 'pool/{0}' -f (Get-ItemPath -Name $Name -Partition $Partition)
    Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential -ErrorAction SilentlyContinue -AsBoolean
}