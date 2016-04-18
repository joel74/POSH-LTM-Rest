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

        [Parameter(Mandatory=$true,ParameterSetName='InputObjectWithAddress',ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true,ParameterSetName='InputObjectWithComputerName',ValueFromPipeline=$true)]
        [Alias("Pool")]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='PoolNameWithAddress',ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true,ParameterSetName='PoolNameWithComputerName')]
        [string[]]$PoolName,

        [Parameter(Mandatory=$false,ParameterSetName='PoolNameWithAddress',ValueFromPipeline=$true)]
        [Parameter(Mandatory=$false,ParameterSetName='PoolNameWithComputerName')]
        [string]$Partition,

        [Parameter(Mandatory=$true,ParameterSetName='InputObjectWithComputerName')]
        [Parameter(Mandatory=$true,ParameterSetName='PoolNameWithComputerName')]
        [string]$ComputerName,

        [Parameter(Mandatory=$true,ParameterSetName='InputObjectWithAddress')]
        [Parameter(Mandatory=$true,ParameterSetName='PoolNameWithAddress')]
        [IPAddress]$Address,

        [Parameter(Mandatory=$false)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [ValidateRange(0,65535)]
        [int]$PortNumber,
    
        [Parameter(Mandatory=$false)]
        [string]$Description=$ComputerName,

        [ValidateSet("Enabled","Disabled")]
        [Parameter(Mandatory=$true)]$Status
    )

    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        if ($PSCmdLet.ParameterSetName -match 'ComputerName$') {
            $Address = [Net.Dns]::GetHostAddresses($ComputerName) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }  | Select-Object -First 1
        }
    }

    process {
#        $Address.IPAddressToString
#        $PSCmdLet.ParameterSetName

        switch -Wildcard ($PSCmdLet.ParameterSetName) {
            "InputObjectWith*" {
                switch ($InputObject.kind) {
                    "tm:ltm:pool:poolstate" {
                        if (!$Address) {
                            Write-Error 'Address is required when the pipeline object is not a PoolMember'
                        } else {
                            if (!$Name) {
                                $Name = '{0}:{1}' -f $Address.IPAddressToString,$PortNumber
                            }
                            if ($Name -notmatch ':\d+$') {
                                $Name = '{0}:{1}' -f $Name,$PortNumber
                            }
                            foreach($pool in $InputObject) {
                                if (!$Partition) {
                                    $Partition = $pool.partition 
                                }
                                $JSONBody = @{name=$Name;partition=$Partition;address=$Address.IPAddressToString;description=$Description}
                                if (Test-Node -F5Session $F5Session -Name $Address -Partition $Partition) {
                                    # Node exists, just add using name
                                    $JSONBody = @{name=$Name}
                                } # else the node will be created
                                $JSONBody = $JSONBody | ConvertTo-Json
                                $MembersLink = $F5session.GetLink($pool.membersReference.link)
                                Invoke-RestMethodOverride -Method POST -Uri "$MembersLink" -Credential $F5session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to add $Name to $($pool.name)." | Add-ObjectDetail -TypeName 'PoshLTM.PoolMember'

                                #After adding to the pool, make sure the member status is set as specified
                                If ($Status -eq "Enabled"){
                                    $pool | Get-PoolMember -F5Session $F5Session -Address $Address -Name $Name | Enable-PoolMember -F5session $F5Session 
                                }
                                ElseIf ($Status -eq "Disabled"){
                                    $pool | Get-PoolMember -F5Session $F5Session -Address $Address -Name $Name | Disable-PoolMember -F5session $F5Session 
                                }
                            }
                        }
                    }
                }
            }
            "PoolNameWith*" {
                foreach($pName in $PoolName) {
                    Get-Pool -F5Session $F5Session -PoolName $pName -Partition $Partition | Add-PoolMember -F5session $F5Session -Address $Address -Name $Name -PortNumber $PortNumber -Status $Status
                }
            }
        }
    }
}