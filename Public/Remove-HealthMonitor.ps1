Function Remove-HealthMonitor {
<#
.SYNOPSIS
    Remove the specified health monitor. Confirmation is needed
.NOTES
    Health monitor names are case-specific.
#>
    [cmdletBinding( SupportsShouldProcess=$true, ConfirmImpact="Low")]    
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias('HealthMonitor')]
        [Alias('Monitor')]
        [PSObject[]]$InputObject,
        
        [Parameter(Mandatory=$true,ParameterSetName='Name',ValueFromPipeline=$true)]
        [string[]]$Name,
        
        [Parameter(Mandatory=$false,ParameterSetName='Name')]
        [string[]]$Type,
        
        [Parameter(Mandatory=$false)]
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
                foreach($monitor in $InputObject) {
                    if ($pscmdlet.ShouldProcess($monitor.fullPath)){
                        $URI = $F5Session.GetLink($monitor.selfLink)
                        Invoke-RestMethodOverride -Method DELETE -Uri $URI -Credential $F5Session.Credential -AsBoolean
                    }
                }
            }
            Name {
                Get-HealthMonitor -F5Session $F5Session -Name $Name -Type $Type -Partition $Partition | Remove-HealthMonitor -F5session $F5Session
            }
        }
    }
}
