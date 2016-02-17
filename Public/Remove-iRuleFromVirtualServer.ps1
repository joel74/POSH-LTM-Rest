Function Remove-iRuleFromVirtualServer {
<#
.SYNOPSIS
    Remove an iRule from the specified virtual server
.NOTES
    This function defaults to the /Common partition
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$VirtualServer,
        [Parameter(Mandatory=$true)]$iRuleName
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    #Get the existing IRules on the virtual server
    [array]$iRules = Get-VirtualServeriRuleCollection -VirtualServer $VirtualServer -F5session $F5session

    #If there are no iRules on this virtual server, then create a new array
    If (!$iRules){
        $iRules = @()
    }  

    #Check that the specified iRule is in the collection 
    If ($iRules -match $iRuleName){

        $iRules = $iRules | Where-Object { $_ -ne $iRuleName }

        $VirtualserverIRules = $F5session.BaseURL + 'virtual/{0}' -f ($VirtualServer -replace '[/\\]','~')

        $JSONBody = @{rules=$iRules} | ConvertTo-Json

        Invoke-RestMethodOverride -Method PUT -Uri "$VirtualserverIRules" -Credential $F5session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to remove the $iRuleName iRule from the $VirtualServer virtual server." -AsBoolean
    }
    Else {
        Write-Warning "The $VirtualServer virtual server does not contain the $iRuleName iRule."
        $false
    }

}
