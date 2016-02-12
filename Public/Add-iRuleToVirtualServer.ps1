Function Add-iRuleToVirtualServer {
<#
.SYNOPSIS
    Add an iRule to the specified virtual server
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

    #Verify that the iRule exists on the F5 LTM
    $AlliRules = Get-iRuleCollection -F5session $F5session
    If ($AlliRules.fullPath -notcontains $iRuleName){
        Write-Warning "The $iRuleName iRule does not exist in this F5 LTM."
        Return($false)
    }

    #Verify that this virtual server exists
    If (!(Test-VirtualServer -F5session $F5session -VirtualServerName $VirtualServer)){
        Write-Warning "The $VirtualServer virtual server does not exist."
        Return($false)
    }

    #Get the existing IRules on the virtual server
    [array]$iRules = Get-VirtualServeriRuleCollection -VirtualServer $VirtualServer -F5session $F5session

    #If there are no iRules on this virtual server, then create a new array
    If (!$iRules){
        $iRules = @()
    }        

    #Check that the specified iRule is not already in the collection 
    If ($iRules -match $iRuleName){
        Write-Warning "The $VirtualServer virtual server already contains the $iRuleName iRule."
        Return($false)
    }
    Else {
        $iRules += $iRuleName

        $VirtualserverIRules = $F5session.BaseURL + 'virtual/{0}' -f ($VirtualServer -replace '[/\\]','~')

        $JSONBody = @{rules=$iRules} | ConvertTo-Json

        Try {
            $response = Invoke-RestMethodOverride -Method PUT -Uri "$VirtualserverIRules" -Credential $F5session.Credential -Body $JSONBody -ContentType 'application/json'
            $true
        }
        Catch {
            Write-Error "Failed to add the $iRuleName iRule to the $VirtualServer virtual server."
            Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
            Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
        }

    }

}
