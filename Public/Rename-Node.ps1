Function Rename-Node {
<#
.SYNOPSIS
    Attempts to rename a node.

.DESCRIPTION
    Expects $NodeAddress to be an IPAddress object. 
    $NodeName is optional, and will default to the IPAddress is not included
    Returns the new node definition

.EXAMPLE
    Rename-Node -F5Session $F5Session -Name "MyNodeName" -Address 10.0.0.1 -Description "My node description"

#>   
    [cmdletBinding()]
    param (
        [Alias("Name")]
        [Parameter(Mandatory=$true)]
        [String]$NodeName,

        [Alias("NewName")]
        [Parameter(Mandatory=$false)]
        [String]$NodeNewName,
        
        [Parameter(Mandatory=$false)]
        [String]$Partition,
        
        $F5Session=$Script:F5Session
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }
    process {
        # Get the node
        $node = Get-Node -F5Session $F5Session -Name $NodeName;
        Write-Verbose "Node retrieved - $($node | ConvertTo-Json -Compress)";

        # Attempt to delete the node (errors if in use)
        Remove-Node -F5Session $F5Session -InputObject $node;
        Write-Verbose "Node removed";

        # Create the new node
        $node.name = $NodeNewName;                                                # We want to add the new object the way it was before
        if ($node.session -like 'monitor-*') { $node.session = 'user-enabled' }   # Create fails if we try to set the session to monitor-disabled or monitor-enabled
        $properties = $node | Select-Object * -ExcludeProperty @("selfLink", "kind", "generation", "state")
        $newNode = New-Node -Properties $properties -PassThrough
        Write-Verbose "Node added - $($newNode | ConvertTo-Json -Compress)";
    }
}