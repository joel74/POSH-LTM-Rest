Function Disable-Node {
<#
.SYNOPSIS
    Disable a node to quickly disable all pool members associated with it
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$false,ParameterSetName='AddressOrName',ValueFromPipelineByPropertyName=$true)]
        [PoshLTM.F5Address[]]$Address=[IPAddress]::Any,
	
        [Alias('ComputerName')]
        [Alias('NodeName')]
        [Parameter(Mandatory=$false,ParameterSetName='AddressOrName',ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',

        [Parameter(Mandatory=$false,ParameterSetName='AddressOrName',ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,
        
        [switch]$Force
    )
    begin {
        #If the -Force param is specified pool members do not accept any new connections, even if they match an existing persistence session.
        #Otherwise, members will only accept new connections that match an existing persistence session.
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            AddressOrName {
                Get-Node -F5session $F5Session -Address $Address -Partition $Partition -Name $Name | Disable-Node -F5session $F5Session -Force:$Force
            }
            InputObject {
                If ($Force){
                    $AcceptNewConnections = "user-down"
                }
                Else {
                    $AcceptNewConnections = "user-up"
                }
                $JSONBody = @{state=$AcceptNewConnections;session='user-disabled'} | ConvertTo-Json
                foreach($member in $InputObject) {
                    $URI = $F5Session.GetLink($member.selfLink)
                    Invoke-F5RestMethod -Method PATCH -Uri "$URI" -F5Session $F5Session -Body $JSONBody -ErrorMessage "Failed to disable node $($member.Name)." -AsBoolean
                }
            }
        }
    }
}