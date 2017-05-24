Function Get-Node {
<#
.SYNOPSIS
    Retrieve specified Node(s)
.NOTES
    This function makes no attempt to resolve names to ip addresses.  If you are having trouble finding a node, try:
        Get-Node | Where-Object { $_.address -like 'N.N.N.N' -or $_.name -like 'XXXXX' }
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [PoshLTM.F5Address[]]$Address=[IPAddress]::Any,

        [Alias('ComputerName')]
        [Alias('NodeName')]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }
    process {
        foreach ($itemname in $Name) {
            $URI = $F5Session.BaseURL + 'node/{0}' -f (Get-ItemPath -Name $itemname -Partition $Partition)
            $JSON = Invoke-F5RestMethod -Method Get -Uri $URI -F5Session $F5Session
            Invoke-NullCoalescing {$JSON.items} {$JSON} | 
                Where-Object { $Address -eq [IPAddress]::Any -or ([string[]]$Address) -contains $_.address} |
                Add-ObjectDetail -TypeName 'PoshLTM.Node'
        }
    }
}