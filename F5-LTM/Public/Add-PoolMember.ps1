Function Add-PoolMember{
<#
.SYNOPSIS
    Add a computer to a pool as a member
.LINK
[Modifying pool members](https://devcentral.f5.com/questions/modifying-pool-members-through-rest-api)
[Add a pool with an existing node member](https://devcentral.f5.com/questions/add-a-new-pool-with-an-existing-node)
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias("Pool")]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,

        [Parameter(Mandatory=$false)]
        [PoshLTM.F5Address]$Address,

        [Parameter(Mandatory=$false)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [ValidateRange(0,65535)]
        [int]$PortNumber,

        [Parameter(Mandatory=$false)]
        [string]$Description,

        [ValidateSet("Enabled","Disabled")]
        [Parameter(Mandatory=$true)]$Status,

        [Alias('iApp')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Application='',

        [Parameter(Mandatory=$false)]
        [int]$RouteDomain

    )

    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        #If both Address and RouteDomain are passed in, then append RouteDomain to Address
        if ($Address -and $RouteDomain) {
            $Address = "{0}%{1}" -f $Address.IPAddress.IPAddressToString, $RouteDomain.ToString()
        }

        #First check for an existing node by name, then by IP address
        #NB: FQDN node will not have a value for IP address
        If ($Name){
            #Strip out any port info when checking for an existing node
            $Node = $Name -replace ':\d+$',''
            $ExistingNode = Get-Node -F5Session $F5Session -Name $Node -Partition $Partition -ErrorAction SilentlyContinue
        }
        ElseIf ($Address){
            $ExistingNode = Get-Node -F5Session $F5Session -Address $Address -Partition $Partition -ErrorAction SilentlyContinue
        }
        Else {
            Write-Error 'Either a name or an IP address is required.'
        }

    }

    process {
        switch ($PSCmdLet.ParameterSetName) {
            'InputObject' {
                switch ($InputObject.kind) {
                    "tm:ltm:pool:poolstate" {
                        If ($Address){
                            $AddressString = $Address.ToString()
                            # Default name to IPAddress
                            if (!$Name) {
                                $Name = '{0}:{1}' -f $AddressString, $PortNumber
                            }
                        }
                        # Append port number if not already present
                        if ($Name -notmatch ':\d+$') {
                            $Name = '{0}:{1}' -f $Name,$PortNumber
                        }
                        foreach($pool in $InputObject) {
                            if (!$Partition) {
                                $Partition = $pool.partition
                            }
                            $JSONBody = @{name=$Name;partition=$Partition;address=$AddressString;description=$Description}
                            if ($ExistingNode) {
                                # Node exists, just add using name
                                $JSONBody = @{name=('{0}:{1}' -f $ExistingNode.name,$PortNumber);partition=('{0}' -f $Partition);description=$Description}
                            } # else the node will be created
                            $JSONBody = $JSONBody | ConvertTo-Json
                            $MembersLink = $F5session.GetLink($pool.membersReference.link)
                            Invoke-F5RestMethod -Method POST -Uri "$MembersLink" -F5Session $F5Session -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to add $Name to $($pool.name)." | Add-ObjectDetail -TypeName 'PoshLTM.PoolMember'

                            #Retrieve the pool member so it can be enabled / disabled
                            If ($Address){
                                $poolMember = $pool | Get-PoolMember -F5Session $F5Session -Address $Address -Application $Application
                            }
                            If ($Name){
                                $poolMember = $pool | Get-PoolMember -F5Session $F5Session -Name $Name -Application $Application
                            }

                            #After adding to the pool, make sure the member status is set as specified
                            If ($Status -eq "Enabled"){
                                $poolMember | Enable-PoolMember -F5session $F5Session | Out-Null
                            }
                            ElseIf ($Status -eq "Disabled"){
                                $poolMember | Disable-PoolMember -F5session $F5Session | Out-Null

                            }
                        }
                    }
                }
            }
            'PoolName' {
                foreach($pName in $PoolName) {

                    $pool = Get-Pool -F5Session $F5Session -PoolName $pName -Partition $Partition -Application $Application 
                    If ($Address){
                        $pool | Add-PoolMember -F5session $F5Session -Address $Address -Name $Name -Description $Description -PortNumber $PortNumber -Status $Status -Application $Application
                    }
                    Else {
                        $pool | Add-PoolMember -F5session $F5Session -Name $Name -Description $Description -PortNumber $PortNumber -Status $Status -Application $Application
                    }
                }
            }
        }
    }
}