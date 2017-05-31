Function Remove-Node {
<#
.SYNOPSIS
    Remove the specified Node(s)
.NOTES
    Node names are case-specific.
#>
    [cmdletBinding( DefaultParameterSetName='Address', SupportsShouldProcess, ConfirmImpact='Medium')]
    param (
        $F5Session=$Script:F5Session,

        [Alias('Node')]
        [Parameter(Mandatory,ParameterSetName='InputObject',ValueFromPipeline)]
        [PSObject[]]$InputObject,

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
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                foreach($item in $InputObject) {
                    if ($pscmdlet.ShouldProcess($item.fullPath)){
                        $URI = $F5Session.GetLink($item.selfLink)
                        Invoke-F5RestMethod -Method DELETE -Uri $URI -F5Session $F5Session
                    }
                }
            }
            default {
                Get-Node -F5Session $F5Session -Address $Address -Name $Name -Partition $Partition | Remove-Node -F5session $F5Session
            }
        }
    }
}