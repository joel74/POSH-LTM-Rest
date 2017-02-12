Function Get-HealthMonitorType {
<#
.SYNOPSIS
    Retrieve the specified health monitor type(s).
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,

        [Alias('Type')]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='*'
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }
    process {
        foreach ($itemname in $Name) {
            $URI = $F5Session.BaseURL + 'monitor/'
            $JSON = Invoke-F5RestMethod -Method Get -Uri $URI -F5Session $F5Session
            $JSON.items.reference | ForEach-Object { 
                [Regex]::Match($_.Link,'(?<=/)[^/?]*(?=\?)').Value |
                    Where-Object { $_ -like $itemname }
            }
        }
    }    
}
