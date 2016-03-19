Function Get-PoolMonitor {
<#
.SYNOPSIS
    Get details about the specified pool monitor
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias('Pool')]
        [PSObject[]]$InputObject,
        
        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [Alias("PoolName")]
        [string[]]$Name,

        [Parameter(Mandatory=$false,ParameterSetName='PoolName')]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                $InputObject | ForEach-Object { ($_ | Select-Object -ExpandProperty monitor) -split ' and ' }
            }
            PoolName {
                Get-Pool -F5Session $F5Session -Name $Name -Partition $Partition | Get-PoolMonitor -F5Session $F5Session 
            }
        }
    }
}
