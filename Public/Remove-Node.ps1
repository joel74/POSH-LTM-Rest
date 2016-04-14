Function Remove-Node {
<#
.SYNOPSIS
    Remove the specified node. Confirmation is needed
.NOTES
    Node names are case-specific.
#>
    [cmdletBinding( SupportsShouldProcess=$true, ConfirmImpact="High")]    
    param (
        [Alias('Node')]
        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

       
        [Alias("NodeName")]
        [Parameter(Mandatory=$true,ParameterSetName='Name',ValueFromPipeline=$true)]
        [string[]]$Name,
        [Parameter(Mandatory=$false)]
        [string]$Partition,

        $F5Session=$Script:F5Session        
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Node names are case-specific."
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            Name {
                Get-Node -F5Session $F5Session -Name $Name -Partition $Partition | Remove-Node -F5session $F5Session
            }
            InputObject {
                foreach($node in $InputObject) {
                    if ($pscmdlet.ShouldProcess($node.fullPath)){
                        $URI = $F5Session.GetLink($node.selfLink)
                        Invoke-RestMethodOverride -Method DELETE -Uri $URI -Credential $F5Session.Credential
                    }
                }
            }
        }
    }
}
