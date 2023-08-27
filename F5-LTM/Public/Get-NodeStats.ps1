Function Get-NodeStats {
<#
.SYNOPSIS
    Retrieve specified Node(s) statistics
.NOTES
    Node names are case-specific.
#>
    [cmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    param (
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$false)]
        [string]$Partition,

        [Alias('ComputerName')]
        [Alias('NodeName')]
        [Parameter(Mandatory=$true,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string[]]$Name=''

    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Node names are case-specific."
    }
    process {
        for($i=0; $i -lt $Name.Count; $i++) {
            $itemname = Invoke-NullCoalescing {$Name[$i]} {''}
            $URI = $F5Session.BaseURL + 'node/{0}/stats' -f (Get-ItemPath -Name $itemname -Partition $Partition)
            $JSON = Invoke-F5RestMethod -Method Get -Uri $URI -F5Session $F5Session
		    $JSON = Resolve-NestedStats -F5Session $F5Session -JSONData $JSON
            Invoke-NullCoalescing {$JSON.entries} {$JSON} | Add-ObjectDetail
        }
    }
}