Function New-Pool {
<#
.SYNOPSIS
    Create a new pool. Optionally, add pool members to the new pool

.DESCRIPTION
    Expects the $MemberDefinitionList param to be an array of strings. 
    Each string should contain a computer name and a port number, comma-separated.
    Optionally, it can contain a description of the member.

.EXAMPLE
    New-Pool -F5Session $F5Session -PoolName "MyPoolName" -MemberDefinitionList @("Server1,80,Web server","Server2,443,Another web server")

#>   
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,
        [Alias('PoolName')]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,
        
        [string]$Description,

        [ValidateSet('dynamic-ratio-member','dynamic-ratio-node','fastest-app-response','fastest-node','least-connections-member','least-connections-node','least-sessions','observed-member','observed-node','predictive-member','predictive-node','ratio-least-connections-member','ratio-least-connections-node','ratio-member','ratio-node','ratio-session','round-robin','weighted-least-connections-member','weighted-least-connections-node')]
        [Parameter(Mandatory=$true)]
        [string]$LoadBalancingMode,

        [Parameter(Mandatory=$false)]
        [string[]]$MemberDefinitionList=$null
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        $URI = ($F5Session.BaseURL + "pool")
    }
    process {
        foreach ($poolname in $Name) {
            $newitem = New-F5Item -Name $poolname -Partition $Partition 
            #Check whether the specified pool already exists
            If (Test-Pool -F5session $F5Session -Name $newitem.Name -Partition $newitem.Partition){
                Write-Error "The $($newitem.FullPath) pool already exists."
            }
            Else {
                #Start building the JSON for the action
                $JSONBody = @{name=$newitem.Name;partition=$newitem.Partition;description=$Description;loadBalancingMode=$LoadBalancingMode;members=@()} | ConvertTo-Json

                Invoke-F5RestMethod -Method POST -Uri "$URI" -F5Session $F5Session -Body $JSONBody -ContentType 'application/json' -ErrorMessage ("Failed to create the $($newitem.FullPath) pool.") -AsBoolean
                ForEach ($MemberDefinition in $MemberDefinitionList){
                    $Node,$PortNumber = $MemberDefinition -split ','
                    # IP Addresses always start with a number, server names can not
                    if ($Node -match '^\d') {
                        $null = Add-PoolMember -F5Session $F5Session -PoolName $Name -Partition $Partition -Address $Node -PortNumber $PortNumber -Status Enabled
                    } else {
                        $null = Add-PoolMember -F5Session $F5Session -PoolName $Name -Partition $Partition -ComputerName $Node -PortNumber $PortNumber -Status Enabled
                    }
                }
            }
        }
    }
}
