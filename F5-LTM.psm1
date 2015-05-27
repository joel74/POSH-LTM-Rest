<#
AUTHOR: Joel Newton
CREATED DATE: 5/13/15
LAST UPDATED DATE: 5/27/15
VERSION: 1.1

SYNOPSIS

This module uses the F5 LTM REST API to manipulate and query pools and pool members
It is built to work with version 11.6
	    
DEPENDENCIES

It depends on the TunableSSLValidator module authored by Jaykul (https://github.com/Jaykul/Tunable-SSL-Validator) to allow for using the REST API 
with LTM devices using self-signed SSL certificates. If you are not connecting to your LTM(s) via SSL or you're using a trusted 
certificate, then the TunableSSLValidator module is not needed and you can remove the -Insecure parameter from the Invoke-WebRequest calls

#>

Function Get-F5session{
# Generate an F5 session object to be used in querying and changing the F5 LTM
# This function takes the DNS name or IP address of the F5 LTM device, and a username for an account 
# with the privileges modify the LTM via the REST API, and the user's password as a secure string.
# To generate a secure string from plain text, use:
# $F5Password = ConvertTo-SecureString -String $Password -AsPlainText -Force  

    param(
        [Parameter(Mandatory=$true)][string]$LTMName,
        [Parameter(Mandatory=$true)][string]$F5UserName,
        [Parameter(Mandatory=$true)][Security.SecureString]$F5Password        
    )

    $BaseURL = "https://$LTMName/mgmt/tm/ltm/"

    #Create credential object for connecting to REST API
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $F5UserName, $F5Password

    [pscustomobject]@{BaseURL = $BaseURL; Credential = $Credential}
}

Function Test-F5IsActive{
#Test whether the specified F5 is currently in active or standby failover mode

    param (
        [Parameter(Mandatory=$true)]$F5session
    )

    $FailoverPage = $F5Session.BaseURL -replace "/ltm/", "/cm/failover-status"

    $FailoverJSON = Invoke-WebRequest -Insecure -Uri $FailoverPage -Credential $F5Session.Credential

    $FailOver = $FailoverJSON.Content | ConvertFrom-Json

    #This is where the failover status is indicated
    $FailOverStatus = $failover.entries.'https://localhost/mgmt/tm/cm/failover-status/0'.nestedStats.entries.status.description

    #Return the failover status value
    $FailOverStatus

}


Function Get-Pools {
#Get a list of all pools for the specified F5 LTM
    
    param (
        [Parameter(Mandatory=$true)]$F5session
    )

    #Only retrieve the pool names
    $PoolsPage = $F5session.BaseURL + 'pool/?$select=name'

    $PoolsJSON = Invoke-WebRequest -Insecure -Uri $PoolsPage -Credential $F5session.Credential

    $Pools = $PoolsJSON.Content | ConvertFrom-Json

    $Pools.items.name

}


Function Get-PoolMembers {
#Get the members of the specified pool
    param(
        [Parameter(Mandatory=$true)]$PoolName,
        [Parameter(Mandatory=$true)]$F5session
    )

    $PoolMembersPage = $F5session.BaseURL + "pool/~Common~$PoolName/members/?"

    $PoolMembersJSON = Invoke-WebRequest -Insecure -Uri $PoolMembersPage -Credential $F5session.Credential

    $PoolMembers = $PoolMembersJSON.Content | ConvertFrom-Json

    $PoolMembers.items

}

Function Get-AllPoolMembersStatus {
#Get the status of all members of the specified pool

   param(
        [Parameter(Mandatory=$true)]$PoolName,
        [Parameter(Mandatory=$true)]$F5session
    )

    $PoolMembers = Get-PoolMembers -PoolName $PoolName -F5session $F5session | Select-Object -Property name,session,state

    $PoolMembers
}




Function Get-PoolMember {
#Get all details about the specified computer, for all pools of which it is a member
    param(
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$F5session
    )

    $MemberInPools = Get-PoolsForMember -ComputerName $ComputerName -F5session $F5session

    $PoolMember = $null
 
    $PoolMember = ForEach ($Pool in $MemberInPools){

        $IPAddress = Get-PoolMemberIP -ComputerName $ComputerName -PoolName $Pool

        $PoolMemberURI = $F5session.BaseURL + "pool/~Common~$Pool/members/~Common~$IPAddress`?"

        $PoolMemberJSON = Invoke-WebRequest -Insecure -Uri $PoolMemberURI -Credential $F5session.Credential

        $PoolMemberJSON.Content | ConvertFrom-Json

    }

    $PoolMember

}


Function Set-PoolMemberDescription {
# Set the description value for the specified pool member
    param(

        $ComputerName,
        $PoolName,
        $F5Session,
        $Description
    )

    $IPAddress = Get-PoolMemberIP -ComputerName $ComputerName -PoolName $PoolName

    $URI = $F5session.BaseURL + "pool/~Common~$PoolName/members/$IPAddress"

    $JSONBody = @{description=$Description} | ConvertTo-Json

    $response = Invoke-WebRequest -Insecure -Method PUT -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody -Headers @{"Content-Type"="application/json"}


}


Function Get-PoolMemberStatus {
#Get the current session and state values for the specified computer

   param(
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$F5session
    )

    $PoolMember = Get-PoolMember -ComputerName $ComputerName -F5session $F5session

    $PoolMember = $PoolMember | Select-Object -Property name,session,state

    $PoolMember 
}



Function Get-PoolsForMember {
#Determine which pool(s) a server is in

    param(
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$F5session
    )

    #All servers that are LTM pool members use the NIC with a default gateway as the IP that registers with the LTM
    $ComputerIP = Get-WmiObject -ComputerName $ComputerName -Class Win32_NetworkAdapterConfiguration | Where DefaultIPGateway | select -exp IPaddress | select -first 1
    
    $AllPools = Get-Pools -F5session $F5session

    $PoolsFound = @()

    foreach($Pool in $AllPools) 
    {
        $PoolMembers = Get-PoolMembers -PoolName $Pool -F5session $F5session

        foreach($PoolMember in $PoolMembers) {

            if($PoolMember.address -eq $ComputerIP) {
                $PoolsFound += $Pool
            }
        }

    }

    $PoolsFound
}


Function Get-PoolMemberIP {
#Determine the IP address and port for a server in a particular pool

    param(
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName
    )


    $IPAddress = Get-WmiObject -ComputerName $ComputerName -Class Win32_NetworkAdapterConfiguration | Where DefaultIPGateway | select -exp IPaddress | select -first 1

    $Port = $PoolName -replace ".*_",""

    If ($IPAddress -eq $null){
        throw ("This server $ComputerName was not found, or its NIC(s) don't have a default gateway.")
    }
    Else {
        ($IPAddress+":"+$Port)
    }
}



Function Add-PoolMember{
#Add a computer to a pool as a member
    param(
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName,
        [Parameter(Mandatory=$true)]$F5session
    )

    $URI = $F5session.BaseURL + "pool/~Common~$PoolName/members"

    $IPAddress = Get-WmiObject -ComputerName $ComputerName -Class Win32_NetworkAdapterConfiguration | Where DefaultIPGateway | select -exp IPaddress | select -first 1
    $MemberName = $IPAddress + ":" + ($PoolName -replace ".*_","")

    $JSONBody = @{name=$MemberName;address=$IPAddress;description=$ComputerName} | ConvertTo-Json

    $response = Invoke-WebRequest -Insecure -Method POST -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody -Headers @{"Content-Type"="application/json"}

    If ($response.statusCode -eq "200"){
        $true;
    }
    Else {
        ("$($response.StatusCode): $($response.StatusDescription)")
    }
}


Function Remove-PoolMember{
#Remove a computer from a pool
    param(
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName,
        [Parameter(Mandatory=$true)]$F5session
    )

    $ComputerIP = Get-WmiObject -ComputerName $ComputerName -Class Win32_NetworkAdapterConfiguration | Where DefaultIPGateway | select -exp IPaddress | select -first 1
    $MemberName = $ComputerIP + ":" + ($PoolName -replace ".*_","")

    $URI = $F5session.BaseURL + "pool/~Common~$PoolName/members/~Common~$MemberName"
    
    $response = Invoke-WebRequest -Insecure -Method DELETE -Uri "$URI" -Credential $F5session.Credential -Headers @{"Content-Type"="application/json"}

    If ($response.statusCode -eq "200"){
        $true;
    }
    Else {
        ("$($response.StatusCode): $($response.StatusDescription)")
    }
}



Function Disable-PoolMember{
#Disable a pool member
#Members that have been disabled accept only new connections that match an existing persistence session.
    param(
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$F5session
    )

    $Pools = Get-PoolsForMember -ComputerName $ComputerName -F5session $F5session
    $IPAddress = (Get-PoolMember -ComputerName $ComputerName -F5session $F5session).Name

    ForEach ($Pool in $Pools){
    
        $URI = $F5session.BaseURL + "pool/~Common~$Pool/members/$IPAddress"
        $response = Invoke-WebRequest -Insecure -Method Put -Uri "$URI" -Credential $F5session.Credential -Body '{"state": "user-up", "session": "user-disabled"}'

    }
    
}

Function Disable-PoolMemberForced {
#Set a pool member to Forced-Offline
#Members that have been forced offline do not accept any new connections, even if they match an existing persistence session.
    param(
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$F5session
    )

    $Pools = Get-PoolsForMember -ComputerName $ComputerName -F5session $F5session
    $IPAddress = (Get-PoolMember -ComputerName $ComputerName -F5session $F5session).Name

    ForEach ($Pool in $Pools){

        $URI = $F5session.BaseURL + "pool/~Common~$Pool/members/$IPAddress"
        $response = Invoke-WebRequest -Insecure -Method Put -Uri "$URI" -Credential $F5session.Credential -Body '{"state": "user-down", "session": "user-disabled"}'

    }

}

Function Enable-PoolMember {
#Enable a pool member
    param(
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$F5session
    )

    $Pools = Get-PoolsForMember -ComputerName $ComputerName -F5session $F5session
    $IPAddress = (Get-PoolMember -ComputerName $ComputerName -F5session $F5session).Name

    ForEach ($Pool in $Pools){

        $URI = $F5session.BaseURL + "pool/~Common~$Pool/members/$IPAddress"
        $response = Invoke-WebRequest -Insecure -Method Put -Uri "$URI" -Credential $F5session.Credential -Body '{"state": "user-up", "session": "user-enabled"}'

    }

}


Function Get-CurrentConnections {
#Get the count of the specified pool member's current connections
    param(
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName,
        [Parameter(Mandatory=$true)]$F5session

    )

    $IPAddress = (Get-PoolMember -ComputerName $ComputerName -F5session $F5session).Name

    $PoolMember = $F5session.BaseURL + "pool/~Common~$PoolName/members/~Common~$IPAddress/stats"


    $PoolMemberJSON = Invoke-WebRequest -Insecure -Uri $PoolMember -Credential $F5session.Credential

    $PoolMember = $PoolMemberJSON.Content | ConvertFrom-Json

    #Return the number of current connections for this member of this pool
    $PoolMember.entries.'serverside.curConns'.value

}

Function Get-StatusShape {
#Determine the shape to display for a member's current state and session values
    param(
        [Parameter(Mandatory=$true)]$state,
        [Parameter(Mandatory=$true)]$session
    )

    #Determine status shape based on state and session values
    If ($state -eq "up" -and $session -eq "monitor-enabled"){
        $StatusShape = "green-circle"
    }
    ElseIf ($state -eq "up" -and $session -eq "user-disabled"){
        $StatusShape = "black-circle"
    }
    ElseIf ($state -eq "user-down" -and $session -eq "user-disabled"){
        $StatusShape = "black-diamond"
    }
    ElseIf ($state -eq "down" -and $session -eq "monitor-enabled"){
        $StatusShape = "red-diamond"
    }
    ElseIf ($state -eq "unchecked" -and $session -eq "user-enabled"){
        $StatusShape = "blue-square"
    }
    ElseIf ($state -eq "unchecked" -and $session -eq "user-disabled"){
        $StatusShape = "black-square"
    }
    Else{
        #Unknown
        $StatusShape = "black-square"
    }
        
    $StatusShape
}


