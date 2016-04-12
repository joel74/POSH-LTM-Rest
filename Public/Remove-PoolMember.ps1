Function Remove-PoolMember{
<#
.SYNOPSIS
    Remove a computer from a pool
#>
    [cmdletBinding( SupportsShouldProcess=$true, ConfirmImpact="High")]    
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName,
        [Parameter(Mandatory=$false,ParameterSetName='PoolName')]
        [string]$Partition,

        [Alias("ComputerName")]
        [Parameter(Mandatory=$false,ParameterSetName='InputObject')]
        [Parameter(Mandatory=$true,ParameterSetName='PoolName')]
        [string]$Address='*',
        
        [Parameter(Mandatory=$false)]
        [string]$Name,
        [Parameter(Mandatory=$false)]
        $PortNumber
    )
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                switch ($InputObject.kind) {
                    "tm:ltm:pool:poolstate" {
                        if (!$Address) {
                            Write-Error 'Address is required when the pipeline object is not a PoolMember'
                        } else {
                            $InputObject | Get-PoolMember -F5session $F5Session -Address $Address -Name $Name | Remove-PoolMember -F5session $F5Session
                        }
                    }
                    "tm:ltm:pool:members:membersstate" {
                        foreach($member in $InputObject) {
                            if ($pscmdlet.ShouldProcess($member.fullPath)){
                                $URI = $F5Session.GetLink($member.selfLink)
                                Invoke-RestMethodOverride -Method DELETE -Uri $URI -Credential $F5Session.Credential -AsBoolean
                            }
                        }
                    }
                }
            }
            PoolName {
                Get-PoolMember -F5session $F5Session -PoolName $PoolName -Partition $Partition -Address $Address -Name $Name | Remove-PoolMember -F5session $F5Session
            }
        }
    }
}