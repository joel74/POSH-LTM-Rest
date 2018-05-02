Function Remove-ProfileHttp {
<#
.SYNOPSIS
    Remove the specified pool(s). Confirmation is needed.
.NOTES
    ProfileHttp names are case-specific.
#>
    [cmdletBinding( SupportsShouldProcess=$true, ConfirmImpact='High')]
    param (
        $F5Session=$Script:F5Session,

        [Alias('ProfileHttp')]
        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Alias('ProfileHttpName')]
        [Parameter(Mandatory=$true,ParameterSetName='Name',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: ProfileHttp names are case-specific."
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
            Name {
                $Name | Get-ProfileHttp -F5Session $F5Session -Partition $Partition | Remove-ProfileHttp -F5session $F5Session
            }
        }
    }
}
