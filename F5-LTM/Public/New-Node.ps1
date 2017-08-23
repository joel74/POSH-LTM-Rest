Function New-Node {
<#
.SYNOPSIS
    Create Node(s)

.EXAMPLE
    New-Node -Address 192.168.1.42
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='Address',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [PoshLTM.F5Address[]]$Address,

        [Parameter(Mandatory=$true,ParameterSetName='FQDN',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$FQDN,

        [Parameter(Mandatory=$true,ParameterSetName='FQDN',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('ipv4','ipv6')]
        $AddressType,

        [Parameter(Mandatory=$true,ParameterSetName='FQDN',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('enabled','disabled')]
        $AutoPopulate,

        [Parameter(Mandatory=$false,ParameterSetName='FQDN',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [int]$Interval=3600,

        [Parameter(Mandatory=$false,ParameterSetName='FQDN',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [int]$DownInterval=5,

        [Alias('ComputerName')]
        [Alias('NodeName')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Description='',

        [switch]$Passthru
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        $URI = ($F5Session.BaseURL + "node")
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            Address {
                #Process all nodes with IP addresses
                for ([int]$a=0; $a -lt $Address.Count; $a++) {
                    $itemname = $Name[$a]
                    if ([string]::IsNullOrWhiteSpace($itemname)) { 
                        $itemname = $Address[$a].ToString()
                    }
                    $newitem = New-F5Item -Name $itemname -Partition $Partition 
                    #Check whether the specified node already exists
                    If (Test-Node -F5session $F5Session -Name $newitem.Name -Partition $newitem.Partition){
                        Write-Error "The $($newitem.FullPath) node already exists."
                    } else {
                        #Start building the JSON for the action
                        $JSONBody = @{address=$Address[$a].ToString();name=$newitem.Name;partition=$newitem.Partition;description=$Description[$a]} | ConvertTo-Json

                        Invoke-F5RestMethod -Method POST -Uri "$URI" -F5Session $F5Session -Body $JSONBody -ContentType 'application/json' |
                            Out-Null
                        if ($Passthru) {
                            Get-Node -F5Session $F5Session -Name $newitem.Name -Partition $newitem.Partition
                        }
                    }
                }
            }

            FQDN {
                #Process all nodes with fully qualified domain names
                for ([int]$a=0; $a -lt $Name.Count; $a++) {
                    $itemname = $Name[$a].ToString()
                    $newitem = New-F5Item -Name $itemname -Partition $Partition 
                    $itemfqdn = $FQDN[$a]
                    #Check whether the specified node already exists
                    If (Test-Node -F5session $F5Session -Name $newitem.Name -Partition $newitem.Partition){
                        Write-Error "The $($newitem.FullPath) node already exists."
                    } else {
                        #Start building the JSON for the action
                        $JSON_FQDN = @{name=$itemfqdn;partition=$newitem.Partition;'address-family'=$AddressType;autopopulate=$AutoPopulate;interval=$Interval;'down-interval'=$DownInterval} # | ConvertTo-Json
                        $JSONBody = @{name=$itemname;fqdn=$JSON_FQDN} | ConvertTo-Json

                        Invoke-F5RestMethod -Method POST -Uri "$URI" -F5Session $F5Session -Body $JSONBody -ContentType 'application/json' |
                            Out-Null
                        if ($Passthru) {
                            Get-Node -F5Session $F5Session -Name $newitem.Name -Partition $newitem.Partition
                        }
                    }
                }
            }
        }
    }
}