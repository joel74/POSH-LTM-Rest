Function Remove-PoolMember {
<#
.SYNOPSIS
    Remove member node(s) from a pool
.NOTES
    Pool and member names are case-specific.
#>
    [cmdletBinding( SupportsShouldProcess=$true, ConfirmImpact='High')]
    param (
        $F5Session=$Script:F5Session,

        # InputObject could be Pool objects, but should ultimately be PoolMember objects
        [Alias('Pool')]
        [Alias('PoolMember')]
        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName,

        [Parameter(Mandatory=$false,ParameterSetName='PoolName')]
        [string]$Partition,

        [Alias("ComputerName")]
        [Parameter(Mandatory=$false)]
        [string[]]$Address='*',

        [Parameter(Mandatory=$false)]
        [string[]]$Name='*'
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                foreach($item in $InputObject) {
                    switch ($item.kind) {
                        "tm:ltm:pool:poolstate" {
                            if ($Address -or $Name) {
                                $InputObject | Get-PoolMember -F5session $F5Session -Address $Address -Name $Name | Remove-PoolMember -F5session $F5Session
                            } else {
                                Write-Error 'Address and/or Name is required when the pipeline object is not a PoolMember'
                            }
                        }
                        "tm:ltm:pool:members:membersstate" {
                            if ($pscmdlet.ShouldProcess($item.GetFullName())) {
                                $URI = $F5Session.GetLink($item.selfLink)
                                Invoke-RestMethodOverride -Method DELETE -Uri $URI -Credential $F5Session.Credential
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