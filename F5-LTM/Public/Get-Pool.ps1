﻿Function Get-Pool {
<#
.SYNOPSIS
    Retrieve specified pool(s)
.NOTES
    Pool names are case-specific.
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,

        [Alias('PoolName')]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',

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
            $JSON = Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential
            Invoke-NullCoalescing {$JSON.items} {$JSON} |
                Add-ObjectDetail -TypeName 'PoshLTM.Pool'
        }
    }
}

#https://ltm1.example.com/mgmt/tm/ltm/pool/~dev~sharepoint-2010-bmr-443.app~sharepoint-2010-bmr-443_pool

#The URL format is $F5Session.BaseURL + '/pool/~$($Partition)~$($iApp).app~$($Pool)". It looks like Get-VirtualServer and other functions may have a similar problem.