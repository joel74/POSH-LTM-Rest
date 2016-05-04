Function Get-HealthMonitor {
<#
.SYNOPSIS
    Retrieve specified health monitor(s)
.NOTES
    Health monitor names are case-specific.
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,

        [Alias('MonitorName')]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',

        [Alias('iApp')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Application='',

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Type
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Health monitor names are case-specific."
        $TypeSearchErrorAction = $ErrorActionPreference
        if ([string]::IsNullOrEmpty($Type)) {
            $TypeSearchErrorAction = 'SilentlyContinue'
            $Type = Get-HealthMonitorType -F5Session $F5Session
        }
    }
    process {
        foreach ($typename in $Type) {
            foreach ($itemname in $Name) {
                $URI = $F5Session.BaseURL + 'monitor/{0}' -f ($typename,(Get-ItemPath -Name $itemname -Application $Application -Partition $Partition) -join '/')
                $JSON = Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential -ErrorAction $TypeSearchErrorAction
                if ($JSON.items -or $JSON.name) {
                    $items = Invoke-NullCoalescing {$JSON.items} {$JSON}
                    if(![string]::IsNullOrWhiteSpace($Application) -and ![string]::IsNullOrWhiteSpace($Partition)) {
                        $items = $items | Where-Object {$_.fullPath -like "/$Partition/$Application.app/*"}
                    }
                    $items | Add-ObjectDetail -TypeName 'PoshLTM.HealthMonitor' -PropertyToAdd @{type=$typename}
                }
            }
        }
    }
}
