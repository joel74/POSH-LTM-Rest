Function Test-Node {
<#
.SYNOPSIS
    Test whether the specified node(s) exist
.NOTES
    Node names are case-specific.
#>
    [cmdletBinding(DefaultParameterSetName='Address')]
    [OutputType([bool])]
    param (
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory,ParameterSetName='Address',ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory,ParameterSetName='AddressAndName',ValueFromPipelineByPropertyName)]
        [PoshLTM.F5Address[]]$Address=[PoshLTM.F5Address]::Any,

        [Alias('ComputerName')]
        [Alias('NodeName')]
        [Parameter(Mandatory,ParameterSetName='Name',ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory,ParameterSetName='AddressAndName',ValueFromPipeline,ValueFromPipelineByPropertyName)]
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
            $JSON = Invoke-F5RestMethod -Method Get -Uri $URI -F5Session $F5Session -ErrorAction SilentlyContinue
            [bool](
                Invoke-NullCoalescing {$JSON.items} {$JSON} |
                Where-Object { [PoshLTM.F5Address]::IsMatch($itemaddress, $_.address) }
            )
        }
    }
}