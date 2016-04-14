Function Get-Node {
<#
.SYNOPSIS
    Retrieve the specified node
.NOTES
    Node names are case-specific.
#>
    [cmdletBinding()]
    param (
        [Alias("NodeName")]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,

        $F5Session=$Script:F5Session
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
        
        Write-Verbose "NB: Node names are case-specific."
    }
    process {
        foreach ($nodeName in $Name) {
            $URI = $F5Session.BaseURL + 'node/{0}' -f (Get-ItemPath -Name $nodeName -Partition $Partition)
            $JSON = Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential -ErrorMessage "Failed to get the /$Partition*/$nodeName*' node(s)."
            ($JSON.items,$JSON -ne $null)[0] | Add-ObjectDetail -TypeName 'PoshLTM.Node'
        }
    }
}
