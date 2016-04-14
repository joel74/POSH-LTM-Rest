Function New-Node {
<#
.SYNOPSIS
    Create a new node.

.DESCRIPTION
    Expects $NodeAddress to be an IPAddress object. 
    $NodeName is optional, and will default to the IPAddress is not included
    Returns the new node definition

.EXAMPLE
    New-Node -F5Session $F5Session -Name "MyNodeName" -Address 10.0.0.1 -Description "My node description"

#>   
    [cmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ParameterSetName="Simple")]
        [IPAddress]$Address,

        [Parameter(Mandatory=$false, ParameterSetName="Simple")]
        [String]$Partition="Common",
        
        [Parameter(Mandatory=$false, ParameterSetName="Simple")]
        [string]$Name=$null,
        
        [Parameter(Mandatory=$false, ParameterSetName="Simple")]
        [string]$Description=$null,
        
        [Parameter(Mandatory=$true, ParameterSetName="Full" )]
        [PSCustomObject]$Properties=@{},
        
        [Switch]$PassThrough,

        $F5Session=$Script:F5Session
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        switch ($PSCmdlet.ParameterSetName) {
            "Simple" {
                if ($Name -match '^[/\\](?<Partition>[^/\\]*)[/\\](?<Name>[^/\\]*)$') {
                    $Partition = $matches['Partition']
                    $Name = $matches['Name']
                } else {                
                    # Default the name to the address if not provided
                    $Name = ($Name, "$Address", $_ -ne $null)[0]
                }
                $Properties = [PSCustomObject]@{name=$Name;address="$Address";partition=$Partition;description=$Description};
            }
            "Full" { 
                $Name = $Properties.name;
            }
            default { 
                throw "Unable to determine node properties"
            }
        }
    }
    process {
        $URI = ($F5Session.BaseURL + "node")

        #Check whether the specified node already exists
        if (Test-Node -F5Session $F5Session -Name $Name){
            Write-Error "The $Name node already exists."
        } else {
            $JSONBody = $Properties | ConvertTo-Json
            $newNode = Invoke-RestMethodOverride -Method POST -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorMessage ("Failed to create the $Name node.")
            if ($PassThrough) { $newNode }
        }
    }
}
