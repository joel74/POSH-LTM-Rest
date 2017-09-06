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
        [PoshLTM.F5Address[]]$Address,

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
                    $Members = @()
                    #BIG-IP v 11.5 does not support FQDN nodes, and hence nodes require IP addresses and have no 'ephemeral' property
                    if ($F5Session.LTMVersion.Major -eq '11' -and  $F5Session.LTMVersion.Minor -eq '5'){
                        If (!$Address) { $Address = [PoshLTM.F5Address]::Any }
                        $Members = Invoke-NullCoalescing {$JSON.items} {$JSON} | Where-Object { [PoshLTM.F5Address]::IsMatch($Address, $_.address) -and ($Name -eq '*' -or $Name -contains $_.name) }
                    }
                    Else {
                        #Retrieve members that match the IP address
                        #While searching, exclude ephemeral members and members with an IP address value of 'any6', as these reference FQDN nodes
                        If ($Address){
                            $Members += Invoke-NullCoalescing {$JSON.items} {$JSON} | Where-Object { $_.address -ne 'any6' -and $_.ephemeral -eq 'false' } | Where-Object { [PoshLTM.F5Address]::IsMatch($Address, $_.address) }
                        }
                        #Retrieve members via name, including FQDN nodes. Don't include ephemeral IP address-based entries
                        If ($Name -ne '*'){
                            $Members += Invoke-NullCoalescing {$JSON.items} {$JSON} | Where-Object { $_.ephemeral -eq 'false' -and ($Name -contains $_.name) }
                        }
                        #Retrieve all non-ephemeral pool members, if no address or name is passed in
                        If (!$Address -and $Name -eq '*'){
                            $Members += Invoke-NullCoalescing {$JSON.items} {$JSON} | Where-Object { $_.ephemeral -eq 'false' }
                        }
                    }
                    #Add selfLink() and GetPoolName() methods and PoshLTM.PoolMember object detail
                    $Members | Add-Member -Name GetPoolName -MemberType ScriptMethod {
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