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

        Write-Verbose "NB: Pool and member names are case-specific."
    }
    process {
        if ($Address -ne '*') {
            for ([int]$a=0; $a -lt $Address.Count; $a++) {
                $ip = [IPAddress]::Any
                if ([IpAddress]::TryParse($Address[$a],[ref]$ip)) {
                    $Address[$a] = $ip.IpAddressToString
                } else {
                    $Address = [string]([System.Net.Dns]::GetHostAddresses($Address).IPAddressToString)
                    #If we don't get an IP address for the computer, try the value specified
                    If ($ip) {
                        $Address[$a] = $ip
                    }
                }
            }
        }
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                if ($null -eq $InputObject) {
                    $InputObject = Get-Pool -F5Session $F5Session -Partition $Partition
                }
                foreach($pool in $InputObject) {
                    $MembersLink = $F5Session.GetLink($pool.membersReference.link)
                    $JSON = Invoke-RestMethodOverride -Method Get -Uri $MembersLink -Credential $F5Session.Credential
                    Invoke-NullCoalescing {$JSON.items} {$JSON} | Where-Object { ($Address -eq '*' -and $Name -eq '*') -or $Address -contains $_.address -or $Name -contains $_.name } | Add-Member -Name GetPoolName -MemberType ScriptMethod {
                        [Regex]::Match($this.selfLink, '(?<=pool/)[^/]*') -replace '~','/'
                    } -Force -PassThru | Add-Member -Name GetFullName -MemberType ScriptMethod {
                        '{0}{1}' -f $this.GetPoolName(),$this.fullPath
                    } -Force -PassThru | Add-ObjectDetail -TypeName 'PoshLTM.PoolMember'
                }
            }
            PoolName {
                Get-Pool -F5Session $F5Session -Name $PoolName -Partition $Partition | Get-PoolMember -F5session $F5Session -Address $Address -Name $Name
            }
        }
    }
}