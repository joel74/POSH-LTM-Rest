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

        [Parameter(ValueFromPipelineByPropertyName)]
        [PoshLTM.F5Address[]]$Address=[PoshLTM.F5Address]::Any,

        [Alias('ComputerName')]
        [Alias('NodeName')]
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string[]]$Name='',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Node names are case-specific."
    }
    process {
        for($i=0; $i -lt $Name.Count -or $i -lt $Address.Count; $i++) {
            $itemname = Invoke-NullCoalescing {$Name[$i]} {''}
            $itemaddress = Invoke-NullCoalescing {$Address[$i]} {[PoshLTM.F5Address]::Any}
            $URI = $F5Session.BaseURL + 'node/{0}' -f (Get-ItemPath -Name $itemname -Partition $Partition)
            $JSON = Invoke-F5RestMethod -Method Get -Uri $URI -F5Session $F5Session
            #BIG-IP v 11.5 does not support FQDN nodes, and hence nodes require IP addresses and have no 'ephemeral' property
            Invoke-NullCoalescing {$JSON.items} {$JSON} |
                Where-Object { $F5Session.LTMVersion.Major -eq '11' -or $_.ephemeral -eq 'false' } |
                Where-Object { [PoshLTM.F5Address]::IsMatch($itemaddress, $_.address) } |
                Add-ObjectDetail -TypeName 'PoshLTM.Node'
        }
    }
}