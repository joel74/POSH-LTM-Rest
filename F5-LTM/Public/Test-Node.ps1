Function Test-Node {
<#
.SYNOPSIS
    Test whether the specified node(s) exist
.NOTES
    Node names are case-specific.
#>
    [cmdletBinding()]
    [OutputType([bool])]
    param (
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='Address',ValueFromPipelineByPropertyName=$true)]
        [string[]]$Address,

        [Alias('ComputerName')]
        [Alias('NodeName')]
        [Parameter(Mandatory=$true,ParameterSetName='Name',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Node names are case-specific."
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            Address {
                foreach ($itemaddress in $Address) {
                    $URI = $F5Session.BaseURL + 'node/{0}' -f (Get-ItemPath -Partition $Partition)
                    $JSON = Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential
                    [bool](
                        Invoke-NullCoalescing {$JSON.items} {$JSON} | 
                        Where-Object { $Address -eq '*' -or $Address -contains $_.address}
                    )
                }
            }
            Name {
                foreach ($itemname in $Name) {
                    $URI = $F5Session.BaseURL + 'node/{0}' -f (Get-ItemPath -Name $itemname -Partition $Partition)
                    Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential -AsBoolean
                }
            }
        }
    }
}