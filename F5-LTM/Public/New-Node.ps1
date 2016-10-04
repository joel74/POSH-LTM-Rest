﻿Function New-Node {
<#
.SYNOPSIS
    Create Node(s)

.EXAMPLE
    New-Node -Address 192.168.1.42
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='Address',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Address,

        [Alias('ComputerName')]
        [Alias('NodeName')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Description='',

        [switch]$Passthru
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        $URI = ($F5Session.BaseURL + "node")
    }
    process {
        for ([int]$a=0; $a -lt $Address.Count; $a++) {
            $itemname = ($Name[$a],$Address[$a] -ne '')[0]
            $newitem = New-F5Item -Name $itemname -Partition $Partition 
            #Check whether the specified node already exists
            If (Test-Node -F5session $F5Session -Name $newitem.Name -Partition $newitem.Partition){
                Write-Error "The $($newitem.FullPath) node already exists."
            } else {
                #Start building the JSON for the action
                $JSONBody = @{address=$Address[$a];name=$newitem.Name;partition=$newitem.Partition;description=$Description[$a]} | ConvertTo-Json

                Invoke-RestMethodOverride -Method POST -Uri "$URI" -WebSession $F5Session.WebSession -Body $JSONBody -ContentType 'application/json' |
                    Out-Null
                if ($Passthru) {
                    Get-Node -F5Session $F5Session -Name $newitem.Name -Partition $newitem.Partition
                }
            }
        }
    }
}