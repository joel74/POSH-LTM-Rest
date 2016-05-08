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

        [Alias('iApp')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Application='',

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: iRule names are case-specific."
    }
    process {
        foreach ($itemname in $Name) {
            $URI = $F5Session.BaseURL + 'rule/{0}' -f (Get-ItemPath -Name $itemname -Application $Application -Partition $Partition)
            $JSON = Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential
            if ($JSON.items -or $JSON.name) {
                $items = Invoke-NullCoalescing {$JSON.items} {$JSON}
                if(![string]::IsNullOrWhiteSpace($Application) -and ![string]::IsNullOrWhiteSpace($Partition)) {
                    $items = $items | Where-Object {$_.fullPath -eq "/$($_.partition)/$Application.app/$($_.name)"}
                }
                $items | Add-ObjectDetail -TypeName 'PoshLTM.iRule'
            }
        }
    }
}