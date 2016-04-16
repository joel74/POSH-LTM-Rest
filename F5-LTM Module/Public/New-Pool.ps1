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
                $JSONBody = @{name=$newitem.Name;partition=$newitem.Partition;members=@()} | ConvertTo-Json

                Invoke-RestMethodOverride -Method POST -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorMessage ("Failed to create the $($newitem.FullPath) pool.") -AsBoolean
                ForEach ($MemberDefinition in $MemberDefinitionList){
                    $Address,$PortNumber = $MemberDefinition -split ','
                    Add-PoolMember -F5Session $F5Session -PoolName $Name -Partition $Partition -Address $Address -PortNumber $PortNumber -Status Enabled
                }
            }
        }
    }
}