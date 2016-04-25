Function Disable-VirtualServer {
<#
.SYNOPSIS
    Disable a virtual server
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,

        [Alias("VirtualServerName")]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',

        [Alias('iApp')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Application,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    process {
        $JSONBody = "{`"disabled`":true}"
        
        foreach ($itemname in $Name) {
            $URI = $F5Session.BaseURL + 'virtual/{0}' -f (Get-ItemPath -Name $itemname -Application $Application -Partition $Partition)
            $JSON = Invoke-RestMethodOverride -Method PATCH -Uri $URI -Credential $F5Session.Credential -Body $JSONBody -ErrorMessage "Failed to disable VirtualServer $itemname." -AsBoolean
            Get-VirtualServer -F5Session $F5Session -Name $Name -Application $Application -Partition $Partition
        }
    }
}