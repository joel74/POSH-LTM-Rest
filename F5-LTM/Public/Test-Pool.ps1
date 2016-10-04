﻿Function Test-Pool {
<#
.SYNOPSIS
    Test whether the specified pool(s) exist
.NOTES
    Pool names are case-specific.
#>
    [cmdletBinding()]
    [OutputType([bool])]
    param (
        $F5Session=$Script:F5Session,

        [Alias('PoolName')]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,

        [Alias('iApp')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Application,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Pool names are case-specific."
    }
    process {
        foreach ($itemname in $Name) {
            $URI = $F5Session.BaseURL + 'pool/{0}' -f (Get-ItemPath -Name $itemname -Application $Application -Partition $Partition)
            Invoke-RestMethodOverride -Method Get -Uri $URI -WebSession $F5Session.WebSession -AsBoolean
        }
    }
}