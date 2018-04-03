Function Get-ProfileHttp {
<#
.SYNOPSIS
    Retrieve specified Profile(s)
.NOTES
    Profil names are case-specific.
.EXAMPLE
    Get-Profilehttp -F5Session $F5Session -Name $ProfilName -Partition $Partition
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,

        [Alias('ProfileName')]
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
        foreach ($itemname in $Name) {
            $URI = $F5Session.BaseURL + 'profile/http/{0}' -f (Get-ItemPath -Name $itemname -Partition $Partition)
            $JSON = Invoke-F5RestMethod -Method Get -Uri $URI -F5Session $F5Session 
            if ($JSON.items -or $JSON.name) {
                $items = Invoke-NullCoalescing {$JSON.items} {$JSON}
                $items | Add-ObjectDetail -TypeName 'PoshLTM.ProfileHttp'
            }
        }
    }
}