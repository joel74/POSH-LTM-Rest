Function Get-VirtualServer{
<#
.SYNOPSIS
    Retrieve the specified virtual server
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,
        [Alias("VirtualServerName")]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [string[]]$Name,
        [Parameter(Mandatory=$false)]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Virtual server names are case-specific."
        if ([string]::IsNullOrWhitespace($Name)) {
            $Name = ''
        }
    }
    process {
        foreach ($virtualserver in $Name) {
            $Uri = $F5session.BaseURL + 'virtual/{0}' -f (Get-ItemPath -Name $virtualserver -Partition $Partition)
            $JSON = Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5session.Credential
            if ($JSON.items -or $JSON.name) {
                ($JSON.items,$JSON -ne $null)[0] | Add-ObjectDetail -TypeName 'PoshLTM.VirtualServer'
            }
        }
    }
}
