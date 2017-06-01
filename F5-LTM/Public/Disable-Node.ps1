Function Disable-Node {
<#
.SYNOPSIS
    Disable a node to quickly disable all pool members associated with it
#>
    [cmdletBinding(DefaultParameterSetName='Address')]
    param (
        $F5Session=$Script:F5Session,

        [Alias('Node')]
        [Parameter(Mandatory,ParameterSetName='InputObject',ValueFromPipeline)]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory,ParameterSetName='Address',ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory,ParameterSetName='AddressAndName',ValueFromPipelineByPropertyName)]
        [PoshLTM.F5Address[]]$Address=[PoshLTM.F5Address]::Any,

        [Alias('ComputerName')]
        [Alias('NodeName')]
        [Parameter(Mandatory,ParameterSetName='Name',ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory,ParameterSetName='AddressAndName',ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string[]]$Name='',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Partition,

        [switch]$Force
    )
    begin {
        #If the -Force param is specified pool members do not accept any new connections, even if they match an existing persistence session.
        #Otherwise, members will only accept new connections that match an existing persistence session.
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
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
            default {
                Get-Node -F5session $F5Session -Address $Address -Name $Name -Partition $Partition | Disable-Node -F5session $F5Session -Force:$Force
            }
        }
    }
}