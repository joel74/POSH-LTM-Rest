﻿Function Add-PoolMember{
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
            [PoshLTM.F5Address]$Address=[PoshLTM.F5Address]::Any,
    
            [Parameter(Mandatory=$false)]
            [string]$Name,
    
            [Parameter(Mandatory=$true)]
            [ValidateRange(0,65535)]
            [int]$PortNumber,
    
            [Parameter(Mandatory=$false)]
            [string]$Description,
    
            [ValidateSet("Enabled","Disabled")]
            [Parameter(Mandatory=$true)]$Status,
    
            [ValidateSet("Enabled","Disabled")]
            [Parameter(Mandatory=$false)]$AutoPopulate,
    
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
    
            If (!$Name -and !$Address){
                Write-Error 'Either a name or an IP address is required.'
            }
            
            #Strip out any port info when checking for an existing node
            $NodeName = $Name -replace ':\d+$',''
    
            $ExistingNode = Get-Node -F5Session $F5Session -Address $Address -Name $NodeName -Partition $Partition -ErrorAction SilentlyContinue
        }
    
        process {
            switch ($PSCmdLet.ParameterSetName) {
                'InputObject' {
                    switch ($InputObject.kind) {
                        "tm:ltm:pool:poolstate" {
                            $AddressString = $Address.ToString()
                            if ($Address -ne [PoshLTM.F5Address]::Any) {
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
    
                                #check for autopopulate
                                if ($AutoPopulate -eq "Enabled"){
                                    $JSONBody = @{name=$Name;partition=$Partition;address=$AddressString;description=$Description; fqdn=@{autopopulate="enabled"; tmName=$name.Substring(0, $name.IndexOf(":"))}} 
                                }
    
                                else {
                                    $JSONBody = @{name=$Name;partition=$Partition;address=$AddressString;description=$Description}
                                }
    
                                if ($ExistingNode) {
    
                                    #check for autopoupulate
                                    if ($AutoPopulate -eq "Enabled"){
                                        $JSONBody = @{name=('{0}:{1}' -f $ExistingNode.name,$PortNumber);partition=('{0}' -f $Partition);description=$Description; fqdn=@{autopopulate="enabled"; tmName=$name.Substring(0, $name.IndexOf(":"))}}
                                    }
                                    
                                    else {
                                    # Node exists, just add using name
                                    $JSONBody = @{name=('{0}:{1}' -f $ExistingNode.name,$PortNumber);partition=('{0}' -f $Partition);description=$Description}
                                    }
    
                                } # else the node will be created
    
                                $JSONBody = $JSONBody | ConvertTo-Json
    
                                $MembersLink = $F5session.GetLink($pool.membersReference.link)
    
                                Invoke-F5RestMethod -Method POST -Uri "$MembersLink" -F5Session $F5Session -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to add $Name to $($pool.name)." | Add-ObjectDetail -TypeName 'PoshLTM.PoolMember'
    
                                #After adding to the pool, make sure the member status is set as specified
                                If ($Status -eq "Enabled"){
    
                                    $pool | Get-PoolMember -F5Session $F5Session -Address $AddressString -Name $Name -Application $Application | Enable-PoolMember -F5session $F5Session | Out-Null
                                }
                                ElseIf ($Status -eq "Disabled"){
                                    $pool | Get-PoolMember -F5Session $F5Session -Address $AddressString -Name $Name -Application $Application | Disable-PoolMember -F5session $F5Session | Out-Null
    
                                }
                            }
                        }
                    }
                }
                'PoolName' {
                    foreach($pName in $PoolName) {
    
                        Get-Pool -F5Session $F5Session -PoolName $pName -Partition $Partition -Application $Application | Add-PoolMember -F5session $F5Session -Address $Address -Name $Name -Description $Description -PortNumber $PortNumber -Status $Status -Application $Application
    
                    }
                }
            }
        }
    }