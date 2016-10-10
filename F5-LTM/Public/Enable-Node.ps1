Function Enable-Node {
<#
.SYNOPSIS
    Enable a node to quickly enable all pool members associated with it
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$false,ParameterSetName='AddressOrName',ValueFromPipelineByPropertyName=$true)]
        [string[]]$Address='*',

        [Alias('ComputerName')]
        [Alias('NodeName')]
        [Parameter(Mandatory=$false,ParameterSetName='AddressOrName',ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',

        [Parameter(Mandatory=$false,ParameterSetName='AddressOrName',ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #If the -Force param is specified pool members do not accept any new connections, even if they match an existing persistence session.
        #Otherwise, members will only accept new connections that match an existing persistence session.
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            AddressOrName {
                Get-Node -F5session $F5Session -Address $Address -Partition $Partition -Name $Name | Enable-Node -F5session $F5Session
            }
            InputObject {
                $JSONBody = @{state='user-up';session='user-enabled'} | ConvertTo-Json
                foreach($member in $InputObject) {
                    $URI = $F5Session.GetLink($member.selfLink)
                    Invoke-RestMethodOverride -Method PATCH -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ErrorMessage "Failed to enable node $($member.Name)." -AsBoolean
                }
            }
        }
    }
}