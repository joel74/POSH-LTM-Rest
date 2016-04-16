Function Remove-HealthMonitor {
<#
.SYNOPSIS
    Remove the specified health monitor(s). Confirmation is needed.
.NOTES
    Health monitor names are case-specific.
#>
    [cmdletBinding( SupportsShouldProcess=$true, ConfirmImpact="Low")]    
    param(
        $F5Session=$Script:F5Session,

        [Alias('HealthMonitor')]
        [Alias('Monitor')]
        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Alias('HealthMonitorName')]
        [Alias('MonitorName')]
        [Parameter(Mandatory=$true,ParameterSetName='Name',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Type,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Health monitor names are case-specific."
        if ([string]::IsNullOrEmpty($Type)) {
            $Type = Get-HealthMonitorType -F5Session $F5Session
        }
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
                $Name | Get-HealthMonitor -F5Session $F5Session -Type $Type -Partition $Partition | Remove-HealthMonitor -F5session $F5Session
            }
        }
    }
}
