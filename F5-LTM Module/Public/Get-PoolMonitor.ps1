Function Get-PoolMonitor {
<#
.SYNOPSIS
    Get pool monitor(s)
.NOTES
    Pool and monitor names are case-specific.
#>
    [cmdletBinding(DefaultParameterSetName='InputObject')]
    param(
        $F5Session=$Script:F5Session,

        [Alias('Pool')]
        [Parameter(Mandatory=$false,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName,

        [Parameter(Mandatory=$false)]
        [string]$Partition,

        [Parameter(Mandatory=$false)]
        [string[]]$Name='*'
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Pool and monitor names are case-specific."
        
        $monitors = @{}
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                if ($null -eq $InputObject) {
                    $InputObject = Get-Pool -F5Session $F5Session -Partition $Partition
                }
                ($InputObject | Select-Object -ExpandProperty monitor -ErrorAction SilentlyContinue) -split ' and ' | ForEach-Object {
                    $monitorname = $_.Trim() 
                    if ($Name -eq '*' -or $Name -contains $monitorname) {
                        $monitors[$monitorname]++
                    }
                }
            }
            PoolName {
                Get-Pool -F5Session $F5Session -Name $PoolName -Partition $Partition | Get-PoolMonitor -F5Session $F5Session -Name $Name
            }
        }
    }
    end {
        foreach ($key in $monitors.Keys) {
            [pscustomobject]@{Name=$key;Count=$monitors[$key]} 
        }         
    }
}
