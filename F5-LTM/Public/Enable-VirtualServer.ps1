Function Enable-VirtualServer {
<#
.SYNOPSIS
    Enable a virtual server
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,

        [Alias('VirtualServer')]
        [Parameter(Mandatory=$false,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Alias("VirtualServerName")]
        [Parameter(Mandatory=$false,ParameterSetName='VirtualServerName',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',

        [Alias('iApp')]
        [Parameter(Mandatory=$false,ParameterSetName='VirtualServerName',ValueFromPipelineByPropertyName=$true)]
        [string]$Application,

        [Parameter(Mandatory=$false,ParameterSetName='VirtualServerName',ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    process {
        $JSONBody = "{`"enabled`":true}"
        switch($PSCmdLet.ParameterSetName) {
            InputObject {
                if ($null -eq $InputObject) {
                    $InputObject = Get-VirtualServer -F5Session $F5Session -Partition $Partition
                }
                foreach($vs in $InputObject) {
                    $URI = $F5Session.GetLink($vs.selfLink)
                    $FullPath = $vs.fullPath
                    $JSON = Invoke-RestMethodOverride -Method PATCH -Uri $URI -Credential $F5Session.Credential -Body $JSONBody
                    Get-VirtualServer -F5Session $F5Session -Name $FullPath
                }
            }
            VirtualServerName {
                foreach ($itemname in $Name) {
                    Get-VirtualServer -F5Session $F5Session -Name $Name -Application $Application -Partition $Partition | Enable-VirtualServer -F5session $F5Session
                }
            }
        }
    }
}