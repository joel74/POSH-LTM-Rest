Function New-VirtualServer{
<#
.SYNOPSIS
    Create a new virtual server
#>
    param (
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$false)]$Kind="tm:ltm:virtual:virtualstate",
        [Parameter(Mandatory=$true)][string]$VirtualServerName,
        [Parameter(Mandatory=$false)]$Description=$null,
        [Parameter(Mandatory=$true)]$DestinationIP,
        [Parameter(Mandatory=$true)]$DestinationPort,
        [Parameter(Mandatory=$false)]$Source='0.0.0.0/0',
        [Parameter(Mandatory=$false)]$DefaultPool=$null,
        [Parameter(Mandatory=$false)][string[]]$ProfileNames=$null,
        [Parameter(Mandatory=$true,ParameterSetName = 'IpProtocol')]
        [ValidateSet("tcp","udp","sctp")]
        [Parameter(Mandatory=$false)]$ipProtocol=$null,
        [Parameter(Mandatory=$false)]$Mask='255.255.255.255',
        [Parameter(Mandatory=$false)]$ConnectionLimit='0'
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $URI = ($F5session.BaseURL + "virtual")

    #Check whether the specified virtual server already exists
    If (Test-VirtualServer -F5session $F5session -VirtualServerName $VirtualServerName){
        Write-Error "The $VirtualServerName virtual server already exists."
    }

    Else {
        $Partition = 'Common'
        if ($VirtualServerName -match '^[/\\](?<Partition>[^/\\]*)[/\\](?<Name>[^/\\]*)$') {
            $Partition = $matches['Partition']
            $VirtualServerName = $matches['Name']
        }

        #Start building the JSON for the action
        $Destination = $DestinationIP + ":" + $DestinationPort
        $JSONBody = @{kind=$Kind;name=$VirtualServerName;description=$Description;partition=$Partition;destination=$Destination;source=$Source;pool=$DefaultPool;ipProtocol=$ipProtocol;mask=$Mask;connectionLimit=$ConnectionLimit}

        #Build array of profile items
        #JN: What happens if a non-existent profile is passed in?
        $ProfileItems = @()
        ForEach ($ProfileName in $ProfileNames){
            $ProfileItems += @{kind='tm:ltm:virtual:profiles:profilesstate';name=$ProfileName}
        }
        $JSONBody.profiles = $ProfileItems

        $JSONBody = $JSONBody | ConvertTo-Json

        Write-Verbose $JSONBody

        Invoke-RestMethodOverride -Method POST -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to retrieve the $VirtualServerName virtual server."
    }

}
