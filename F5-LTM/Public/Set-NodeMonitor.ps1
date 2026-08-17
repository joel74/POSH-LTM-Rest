Function Set-NodeMonitor {
    <#
    .SYNOPSIS
        Set the monitor for a Node
    .DESCRIPTION
        Updates the monitor assigned to an existing Node.
    .PARAMETER InputObject
        The Node object to update (from Get-Node pipeline)
    .PARAMETER Monitor
        The monitor(s) to assign to the node
    .EXAMPLE
        Get-Node -Address 192.168.1.100 | Set-NodeMonitor -Monitor 'none'
    #>
    [CmdletBinding()]
    Param(
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory,ValueFromPipeline)]
        [Alias('Node')]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory)]
        [string]$Monitor
    )
    Process {
        ForEach($node in $InputObject) {
            $JSONBody = @{monitor=$Monitor} | ConvertTo-Json
            $URI = $F5Session.GetLink($node.selfLink)
            Invoke-F5RestMethod -Method PATCH -Uri "$URI" -F5Session $F5Session -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to set the monitor on $($node.name) to $Monitor."
        }
    }
}
