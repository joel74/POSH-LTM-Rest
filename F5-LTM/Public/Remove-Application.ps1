Function Remove-Application
{
<#
.SYNOPSIS
    Retrieve specified application(s) (iApp)
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,

        [Alias('ApplicationName')]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition='Common'
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Application names are case-specific."
    }
    process {
        foreach ($itemname in $Name) {
            $URI = "$($F5Session.RootURL)/mgmt/tm/sys/application/service/~$($Partition)~$($itemname).app~$($itemname)"
            Invoke-F5RestMethod -Method Delete -Uri $URI -F5Session $F5Session
        }
    }
}
Set-Alias -Name Remove-iApp -Value Remove-Application
