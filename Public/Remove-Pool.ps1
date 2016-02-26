Function Remove-Pool{
<#
.SYNOPSIS
    Remove the specified pool. Confirmation is needed
.NOTES
    Pool names are case-specific.
#>
    [cmdletBinding( SupportsShouldProcess=$true, ConfirmImpact="High")]    
    param (
        $F5Session=$Script:F5Session,
        
        [Alias('Pool')]
        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

       
        [Alias("PoolName")]
        [Parameter(Mandatory=$true,ParameterSetName='Name',ValueFromPipeline=$true)]
        [string[]]$Name,
        [Parameter(Mandatory=$false)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Pool names are case-specific."
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            Name {
                Get-Pool -F5Session $F5Session -Name $Name -Partition $Partition | Remove-Pool -F5session $F5Session
            }
            InputObject {
                foreach($pool in $InputObject) {
                    if ($pscmdlet.ShouldProcess($pool.fullPath)){
                        $URI = $F5session.GetLink($pool.selfLink)
                        Invoke-RestMethodOverride -Method DELETE -Uri $URI -Credential $F5session.Credential -AsBoolean
                    }
                }
            }
        }
    }
}
