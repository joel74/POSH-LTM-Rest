﻿Function Add-iRuleToVirtualServer {
<#
.SYNOPSIS
    Add an iRule to the specified virtual server
.NOTES
    This function defaults to the /Common partition
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,
        
        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Alias("VirtualServer")]
        [Alias("VirtualServerName")]
        [Parameter(Mandatory=$true,ParameterSetName='Name',ValueFromPipeline=$true)]
        [string[]]$Name,
        [Parameter(Mandatory=$false)]
        [string]$Partition='Common',
        
        [Parameter(Mandatory=$true)]
        [string]$iRuleName
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            InputObject {

                $iRulePartitionAndName = "/$Partition/$iRuleName"

                #Verify that the iRule exists on the F5 LTM
                $iRule = Get-iRule -F5session $F5Session -Name $iRuleName -Partition $Partition
                If ($iRule -eq $null){
                    Write-Error "The $iRuleName iRule does not exist in this F5 LTM."
                    $false
                } else {
                    foreach($virtualserver in $InputObject) {
                        #Get the existing IRules on the virtual server
                        [array]$iRules = $virtualserver | Select-Object -ExpandProperty rules -ErrorAction SilentlyContinue

                        #If there are no iRules on this virtual server, then create a new array
                        If (!$iRules){
                            $iRules = @()
                        }        

                        #Check that the specified iRule is not already in the collection 
                        If ($iRules -match $iRulePartitionAndName){
                            Write-Warning "The $Name virtual server already contains the $iRuleName iRule."
                            $false
                        }
                        Else {
                            $iRules += $iRulePartitionAndName #$iRuleName

                            $URI = $F5Session.GetLink($virtualServer.selfLink)

                            $JSONBody = @{rules=$iRules} | ConvertTo-Json

                            Invoke-RestMethodOverride -Method PUT -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to add the $iRuleName iRule to the $Name virtual server." -AsBoolean 
                        }
                    }
                }
            }
            Name {
                $virtualservers = $Name | Get-VirtualServer -F5Session $F5Session -Partition $Partition
                if ($null -eq $virtualservers) {
                    Write-Warning "No virtual servers found."
                    $false
                }
                $virtualservers | Add-iRuleToVirtualServer -F5session $F5Session -iRuleName $iRuleName
            }
        }
    }
}
