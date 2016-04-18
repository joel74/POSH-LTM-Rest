Function Remove-VirtualServer{
<#
.SYNOPSIS
    Remove the specified virtual server(s). Confirmation is needed.
.NOTES
    Virtual server names are case-specific.
#>
    [cmdletBinding( SupportsShouldProcess=$true, ConfirmImpact="High")]    
    param (
        $F5Session=$Script:F5Session,

        [Alias('VirtualServer')]
        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Alias('VirtualServerName')]
        [Parameter(Mandatory=$true,ParameterSetName='Name',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Virtual server names are case-specific."
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                foreach($virtualserver in $InputObject) {
                    if ($pscmdlet.ShouldProcess($virtualserver.fullPath)){
                        $URI = $F5Session.GetLink($virtualserver.selfLink)
                        Invoke-RestMethodOverride -Method DELETE -Uri $URI -Credential $F5Session.Credential
                    }
                }
            }
            Name {
                $Name | Get-VirtualServer -F5Session $F5Session -Partition $Partition | Remove-VirtualServer -F5session $F5Session
            }
        }
    }
}