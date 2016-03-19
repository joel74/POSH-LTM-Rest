Function Get-HealthMonitor {
<#
.SYNOPSIS
    Retrieve the specified health monitor
.NOTES
    Health monitor names are case-specific.
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [string[]]$Name='',
        [Parameter(Mandatory=$false)]
        [string[]]$Type,
        [Parameter(Mandatory=$false)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Health monitor names are case-specific."
        $TypeSearchErrorAction = 'Continue'
        if ([string]::IsNullOrEmpty($Type)) {
            $TypeSearchErrorAction = 'SilentlyContinue'
            $Type = Get-HealthMonitorType -F5Session $F5Session
        }
    }
    process {
        foreach ($t in $Type) {
            foreach ($n in $Name) {
                $URI = $F5Session.BaseURL + 'monitor/{0}/{1}' -f $t,(Get-ItemPath -Name $n -Partition $Partition)
                $JSON = Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential -ErrorAction $TypeSearchErrorAction
                if ($JSON.items -or $JSON.defaultsFrom) {
                    ($JSON.items,$JSON -ne $null)[0] |
                        Add-Member -MemberType NoteProperty -Name type -Value $t -PassThru | Add-ObjectDetail -TypeName 'PoshLTM.HealthMonitor'
                        #Add-Member -MemberType ScriptProperty -Name type -Value { [Regex]::Match($this.selfLink,'(?<=monitor/)[^/]*(?=/)').Value } -PassThru
                }
            }
        }
    }
}
