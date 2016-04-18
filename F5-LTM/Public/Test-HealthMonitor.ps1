Function Test-HealthMonitor {
<#
.SYNOPSIS
    Test whether the specified health monitor(s) exist
.NOTES
    HealthMonitor names are case-specific.
#>
    [cmdletBinding()]
    [OutputType([bool])]
    param (
        $F5Session=$Script:F5Session,

        [Alias('MonitorName')]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,
        
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Type
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: HealthMonitor names are case-specific."
    }
    process {
        foreach ($itemname in $Name) {
            $URI = $F5Session.BaseURL + 'monitor/{0}/{1}' -f $Type,(Get-ItemPath -Name $itemname -Partition $Partition)
            Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential -AsBoolean
        }
    }
}
