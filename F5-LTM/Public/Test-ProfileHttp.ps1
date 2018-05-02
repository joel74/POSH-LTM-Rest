Function Test-ProfileHttp {
<#
.SYNOPSIS
    Test whether the specified profile(s) exist
.NOTES
    Profile names are case-specific.

#>
    [cmdletBinding()]
    [OutputType([bool])]
    param (
        $F5Session=$Script:F5Session,

        [Alias('ProfileName')]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Profile names are case-specific."
    }
    process {
        foreach ($itemname in $Name) {
            $URI = $F5Session.BaseURL + 'profile/http/{0}' -f (Get-ItemPath -Name $itemname -Partition $Partition)
            Invoke-F5RestMethod -Method Get -Uri $URI -F5Session $F5Session -AsBoolean
        }
    }
}