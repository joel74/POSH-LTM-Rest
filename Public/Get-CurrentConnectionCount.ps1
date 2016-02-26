Function Get-CurrentConnectionCount {
<#
.SYNOPSIS
    Get the count of the specified pool member's current connections
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias('PoolMember')]
        [PSObject[]]$InputObject,
        
        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName,
        [Parameter(Mandatory=$false,ParameterSetName='PoolName')]
        [string]$Partition,

        [Alias("ComputerName")]
        [Parameter(Mandatory=$false)]
        [string]$Address='*',

        [Parameter(Mandatory=$false)]
        [string]$Name='*'
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            PoolName {
                Get-PoolMember -F5session $F5Session -PoolName $PoolName -Partition $Partition -Address $Address -Name $Name | Get-CurrentConnectionCount -F5Session $F5Session -Address $Address -Name $Name
            }
            InputObject {
                $InputObject | ForEach-Object {
                    $StatsLink = $F5Session.GetLink(($_.selfLink -replace '\?','/stats?'))
                    $JSON = Invoke-RestMethodOverride -Method Get -Uri $StatsLink -Credential $F5Session.Credential
                    # TODO: Establish a type for formatting and return more columns, and consider adding a GetStats() ScriptMethod to PoshLTM.PoolMember  
                    ($JSON.entries,$JSON -ne $null)[0] | Select-Object -ExpandProperty 'serverside.curConns' #| Add-ObjectDetail -TypeName PoshLTM.PoolMemberStats
                }
            }
        }
    }
}