Function Get-PoolMember {
<#
.SYNOPSIS
    Retrieve specified pool member(s)
.NOTES
    Pool and member names are case-specific.
#>
    [cmdletBinding(DefaultParameterSetName='InputObject')]
    param(
        $F5Session=$Script:F5Session,

        [Alias('Pool')]
        [Parameter(Mandatory=$false,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$false,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName='',

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,

        [Parameter(Mandatory=$false)]
        [PoshLTM.F5Address[]]$Address=[PoshLTM.F5Address]::Any,

        [Parameter(Mandatory=$false)]
        [string[]]$Name='*',

        [Alias('iApp')]
        [Parameter(Mandatory=$false)]
        [string]$Application=''
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Pool and member names are case-specific."
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                if ($null -eq $InputObject) {
                    $InputObject = Get-Pool -F5Session $F5Session -Partition $Partition -Application $Application
                }
                foreach($pool in $InputObject) {
                    $MembersLink = $F5Session.GetLink($pool.membersReference.link)
                    $JSON = Invoke-F5RestMethod -Method Get -Uri $MembersLink -F5Session $F5Session
                    Invoke-NullCoalescing {$JSON.items} {$JSON} | Where-Object { [PoshLTM.F5Address]::IsMatch($Address, $_.address) -and ($Name -eq '*' -or $Name -contains $_.name) } | Add-Member -Name GetPoolName -MemberType ScriptMethod {
                        [Regex]::Match($this.selfLink, '(?<=pool/)[^/]*') -replace '~','/'
                    } -Force -PassThru | Add-Member -Name GetFullName -MemberType ScriptMethod {
                        '{0}{1}' -f $this.GetPoolName(),$this.fullPath
                    } -Force -PassThru | Add-ObjectDetail -TypeName 'PoshLTM.PoolMember'
                }
            }
            PoolName {
                Get-Pool -F5Session $F5Session -Name $PoolName -Partition $Partition -Application $Application | Get-PoolMember -F5session $F5Session -Address $Address -Name $Name -Application $Application
            }
        }
    }
}