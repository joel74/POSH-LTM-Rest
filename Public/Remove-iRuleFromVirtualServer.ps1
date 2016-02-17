Function Remove-iRuleFromVirtualServer {
<#
.SYNOPSIS
    Remove an iRule from the specified virtual server
.NOTES
    This function defaults to the /Common partition
#>
    param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,
        
        [Alias("VirtualServer")]
        [Alias("VirtualServerName")]
        [Parameter(Mandatory=$true,ParameterSetName='Name',ValueFromPipeline=$true)]
        [string[]]$Name,
        [Parameter(Mandatory=$false)]
        [string]$Partition,
        
        [Parameter(Mandatory=$true)]
        [string]$iRuleName
    )
    process {

        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        switch($PSCmdLet.ParameterSetName) {
            InputObject {

                foreach($VirtualServer in $InputObject) {
                    #Get the existing IRules on the virtual server
                    [array]$iRules = $VirtualServer | Select-Object -ExpandProperty rules -ErrorAction SilentlyContinue

                    #If there are no iRules on this virtual server, then create a new array
                    If (!$iRules){
                        $iRules = @()
                    }
                    #Check that the specified iRule is in the collection 
                    If ($iRules -match $iRuleName){

                        $iRules = $iRules | Where-Object { $_ -ne $iRuleName }

                        $Uri = $F5Session.GetLink($virtualServer.selfLink)

                        $JSONBody = @{rules=$iRules} | ConvertTo-Json

                        Invoke-RestMethodOverride -Method PUT -Uri "$Uri" -Credential $F5session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to remove the $iRuleName iRule from the $Name virtual server." -AsBoolean 

                    }
                    Else {
                        Write-Warning "The $VirtualServer virtual server does not contain the $iRuleName iRule."
                        $false
                    }
                }

            }

            Name {
                $virtualservers = $Name | Get-VirtualServer -F5Session $F5Session -Partition $Partition

                if ($null -eq $virtualservers) {
                    Write-Warning "No virtual servers found."
                    $false
                }
                $virtualservers | Remove-iRuleFromVirtualServer -F5session $F5Session -iRuleName $iRuleName
            }
        }
    }
}
