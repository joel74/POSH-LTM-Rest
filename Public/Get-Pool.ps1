Function Get-Pool {
<#
.SYNOPSIS
    Retrieve the specified pool
.NOTES
    Pool names are case-specific.
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,
        
        [Alias("PoolName")]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
        
        Write-Verbose "NB: Pool names are case-specific."
    }
    process {
        foreach ($poolname in $Name) {
            $URI = $F5Session.BaseURL + 'pool/{0}' -f (Get-ItemPath -Name $poolname -Partition $Partition)
            $JSON = Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential -ErrorMessage "Failed to get the /$Partition*/$PoolName*' pool(s)."
            ($JSON.items,$JSON -ne $null)[0] | Add-ObjectDetail -TypeName 'PoshLTM.Pool'
        }
    }
}
