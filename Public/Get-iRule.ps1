Function Get-iRule {
<#
.SYNOPSIS
    Retrieve specified iRule(s)
.NOTES
    iRule names are case-specific.
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,
        
        [Alias("iRuleName")]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
        
        Write-Verbose "NB: iRule names are case-specific."
    }
    process {
        foreach ($rulename in $Name) {
            $URI = $F5Session.BaseURL + 'rule/{0}' -f (Get-ItemPath -Name $rulename -Partition $Partition)
            $JSON = Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential -ErrorMessage "Failed to get the /$Partition*/$rulename*' iRule(s)."
            ($JSON.items,$JSON -ne $null)[0] | Add-ObjectDetail -TypeName 'PoshLTM.iRule'
        }
    }
}