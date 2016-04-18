Function New-VirtualServer{
<#
.SYNOPSIS
    Create a new virtual server
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$false)]$Kind="tm:ltm:virtual:virtualstate",
        [Alias('VirtualServerName')]
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$false)][string]$Partition,
        [Parameter(Mandatory=$false)]$Description=$null,
        [Parameter(Mandatory=$true)]$DestinationIP,
        [Parameter(Mandatory=$true)]$DestinationPort,
        [Parameter(Mandatory=$false)]$Source='0.0.0.0/0',
        [Parameter(Mandatory=$false)]$DefaultPool=$null,
        [Parameter(Mandatory=$false)][string[]]$ProfileNames=$null,
        [Parameter(Mandatory=$true,ParameterSetName = 'IpProtocol')]
        [ValidateSet('tcp','udp','sctp')]
        [Parameter(Mandatory=$false)]$ipProtocol=$null,
        [Parameter(Mandatory=$false)]$Mask='255.255.255.255',
        [Parameter(Mandatory=$false)]$ConnectionLimit='0'
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $URI = ($F5Session.BaseURL + "virtual")

    #Check whether the specified virtual server already exists
    If (Test-VirtualServer -F5session $F5Session -Name $Name){
        Write-Error "The $Name virtual server already exists."
    }
    Else {
        $newitem = New-F5Item -Name $Name -Partition $Partition

        #Start building the JSON for the action
        $Destination = $DestinationIP + ":" + $DestinationPort
        $JSONBody = @{kind=$Kind;name=$newitem.Name;description=$Description;partition=$newitem.Partition;destination=$Destination;source=$Source;pool=$DefaultPool;ipProtocol=$ipProtocol;mask=$Mask;connectionLimit=$ConnectionLimit}

        #Build array of profile items
        #JN: What happens if a non-existent profile is passed in?
        $ProfileItems = @()
        ForEach ($ProfileName in $ProfileNames){
            $ProfileItems += @{kind='tm:ltm:virtual:profiles:profilesstate';name=$ProfileName}
        }
        $JSONBody.profiles = $ProfileItems

        $JSONBody = $JSONBody | ConvertTo-Json

        Write-Verbose $JSONBody

        Invoke-RestMethodOverride -Method POST -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to create the $($newitem.FullPath) virtual server."
    }
}