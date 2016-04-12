Function Remove-Node {
<#
.SYNOPSIS
    Remove the specified node(s)
.NOTES
    Node names are case-specific.
#>
    [cmdletBinding( SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        $F5Session=$Script:F5Session,

        [Alias('Node')]
        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='Address',ValueFromPipelineByPropertyName=$true)]
        [string[]]$Address='*',

        [Alias('ComputerName')]
        [Alias('NodeName')]
        [Parameter(Mandatory=$true,ParameterSetName='Name',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Node names are case-specific."
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            Address {
                Get-Node -F5Session $F5Session -Address $Address -Partition $Partition | Remove-Node -F5session $F5Session
            }
            Name {
                $Name | Get-Node -F5Session $F5Session -Address $Address -Partition $Partition | Remove-Node -F5session $F5Session
            }
            InputObject {
                foreach($item in $InputObject) {
                    if ($pscmdlet.ShouldProcess($item.fullPath)){
                        $URI = $F5Session.GetLink($item.selfLink)
                        Invoke-RestMethodOverride -Method DELETE -Uri $URI -Credential $F5Session.Credential
                    }
                }
            }
        }
    }
}