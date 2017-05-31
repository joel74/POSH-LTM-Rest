Function Get-PoolMemberStats {
<#
.SYNOPSIS
    Retrieve pool member statistics
.NOTES
    Pool and member names are case-specific.
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,

        # InputObject could be Pool objects, but should ultimately be PoolMember objects
        [Alias('Pool')]
        [Alias('PoolMember')]
        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName,

        [Parameter(Mandatory=$false)]
        [string]$Partition,

        [Parameter(Mandatory=$false)]
        [PoshLTM.F5Address[]]$Address=[PoshLTM.F5Address]::Any,

        [Parameter(Mandatory=$false)]
        [string[]]$Name='*',

        [Alias('iApp')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Application=''
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
                            if ($Address -ne [PoshLTM.F5Address]::Any -or $Name) {
                                $InputObject | Get-PoolMember -F5session $F5Session -Address $Address -Name $Name -Application $Application | Get-PoolMemberStats -F5session $F5Session
                            } else {
                                Write-Error 'Address and/or Name is required when the pipeline object is not a PoolMember'
                            }
                        }
                        "tm:ltm:pool:members:membersstate" {
                            $URI = $F5Session.GetLink(($item.selfLink -replace '\?','/stats?'))
                            $JSON = Invoke-F5RestMethod -Method Get -Uri $URI -F5Session $F5Session

                            $JSON = Resolve-NestedStats -F5Session $F5Session -JSONData $JSON

                            Invoke-NullCoalescing {$JSON.entries} {$JSON} #|
                                # Add-ObjectDetail -TypeName 'PoshLTM.PoolMemberStats'
                                # TODO: Establish a type for formatting and return more columns, and consider adding a GetStats() ScriptMethod to PoshLTM.PoolMember
                        }
                    }
                }
            }
            PoolName {
                Get-PoolMember -F5session $F5Session -PoolName $PoolName -Partition $Partition -Address $Address -Name $Name -Application $Application | Get-PoolMemberStats -F5Session $F5Session
            }
        }
    }
}