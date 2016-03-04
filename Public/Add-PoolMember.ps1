Function Add-PoolMember{
<#
.SYNOPSIS
    Add a computer to a pool as a member
.LINK
[Modifying pool members](https://devcentral.f5.com/questions/modifying-pool-members-through-rest-api)
[Add a pool with an existing node member](https://devcentral.f5.com/questions/add-a-new-pool-with-an-existing-node)
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias("Pool")]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName,
        [Parameter(Mandatory=$false,ParameterSetName='PoolName')]
        [string]$Partition,

        [Alias("ComputerName")]
        [Parameter(Mandatory=$true)]
        [string]$Address,

        [Parameter(Mandatory=$false)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        $PortNumber,
	
        [ValidateSet("Enabled","Disabled")]
        [Parameter(Mandatory=$true)]$Status
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        $ComputerName = $Address
		$ip = [IPAddress]::Any
        if ([IpAddress]::TryParse($Address,[ref]$ip)) {
			$Address = $ip.IpAddressToString
		} else {
            $Address = [string]([System.Net.Dns]::GetHostAddresses($Address).IPAddressToString)
            #If we don't get an IP address for the computer, then fail
            If (!($Address)){
                Write-Error "Failed to obtain IP address for $Address. The error returned was:`r`n$Error[0]"
            }
        }
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                switch ($InputObject.kind) {
                    "tm:ltm:pool:poolstate" {
                        if (!$Address) {
                            Write-Error 'Address is required when the pipeline object is not a PoolMember'
                        } else {
                            if (!$Name) {
                                $Name = $Address + ":" + $PortNumber
                            }
                            foreach($pool in $InputObject) {
                                if (!$Partition) {
                                    $Partition = $pool.partition 
                                }
                                $JSONBody = @{name=$Name;partition=$Partition;address=$Address;description=$ComputerName} | ConvertTo-Json
                                $MembersLink = $F5session.GetLink($pool.membersReference.link)
                                Invoke-RestMethodOverride -Method POST -Uri "$MembersLink" -Credential $F5session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to add $ComputerName to $PoolName." | Add-ObjectDetail -TypeName 'PoshLTM.PoolMember'

                                #After adding to the pool, make sure the member status is set as specified
                                If ($Status -eq "Enabled"){
                                    $pool | Get-PoolMember -F5Session $F5Session -Address $Address -Name $Name | Enable-PoolMember -F5session $F5session 
                                }
                                ElseIf ($Status -eq "Disabled"){
                                    $pool | Get-PoolMember -F5Session $F5Session -Address $Address -Name $Name | Disable-PoolMember -F5session $F5session 
                                }
                            }
                        }
                    }
                }
            }
            PoolName {
                foreach($pName in $PoolName) {
                    Get-Pool -F5Session $F5Session -PoolName $pName -Partition $Partition | Add-PoolMember -F5session $F5Session -Address $ComputerName -Name $Name -PortNumber $PortNumber -Status $Status
                }
            }
        }
    }
}