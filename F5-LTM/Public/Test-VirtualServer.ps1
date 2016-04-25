Function Test-VirtualServer {
<#
.SYNOPSIS
    Test whether the specified virtual server(s) exist
.NOTES
    Virtual server names are case-specific.
#>
    [cmdletBinding()]
    [OutputType([bool])]
    param (
        $F5Session=$Script:F5Session,

        [Alias("VirtualServerName")]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,

        [Alias('iApp')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Application,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Virtual server names are case-specific."
    }
    process {
        foreach ($itemname in $Name) {
            $URI = $F5Session.BaseURL + 'virtual/{0}' -f (Get-ItemPath -Name $itemname -Application $Application -Partition $Partition)
            Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential -AsBoolean
        }
    }
}
