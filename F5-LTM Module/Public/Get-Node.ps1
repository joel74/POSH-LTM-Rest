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
        [string[]]$Address='*',

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
            $JSON = Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential
            Invoke-NullCoalescing {$JSON.items} {$JSON} | 
                Where-Object { $Address -eq '*' -or $Address -contains $_.address} |
                Add-ObjectDetail -TypeName 'PoshLTM.Node'
        }
    }
}