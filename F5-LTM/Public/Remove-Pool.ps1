Function Remove-Pool {
<#
.SYNOPSIS
    Remove the specified pool(s). Confirmation is needed.
.NOTES
    Pool names are case-specific.
#>
    [cmdletBinding( SupportsShouldProcess=$true, ConfirmImpact='High')]
    param (
        $F5Session=$Script:F5Session,

        [Alias('Pool')]
        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Alias('PoolName')]
        [Parameter(Mandatory=$true,ParameterSetName='Name',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Pool names are case-specific."
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                foreach($item in $InputObject) {
                    if ($pscmdlet.ShouldProcess($item.fullPath)){
                        $URI = $F5Session.GetLink($item.selfLink)
                        Invoke-RestMethodOverride -Method DELETE -Uri $URI -Credential $F5Session.Credential
                    }
                }
            }
            Name {
                $Name | Get-Pool -F5Session $F5Session -Partition $Partition | Remove-Pool -F5session $F5Session
            }
        }
    }
}
