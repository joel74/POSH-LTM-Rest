<#
.SYNOPSIS  
    A module for using the F5 LTM REST API to administer an LTM device
.DESCRIPTION  
    This module uses the F5 LTM REST API to manipulate and query pools, pool members, virtual servers and iRules
    It is built to work with version 11.6
.NOTES  
    File Name    : F5-LTM.psm1
    Author       : Joel Newton - jnewton@springcm.com
    Requires     : PowerShell V3
    Dependencies : It includes a Validation.cs class file (based on code posted by Brian Scholer) to allow for using the REST API 
    with LTM devices using self-signed SSL certificates.
#>


Add-Type -Path "${PSScriptRoot}\Validation.cs"

Function Get-F5session{
<#
.SYNOPSIS
    Generate an F5 session object to be used in querying and changing the F5 LTM
.DESCRIPTION
    This function takes the DNS name or IP address of the F5 LTM device, and a username for an account 
    with the privileges modify the LTM via the REST API, and the user's password as a secure string.
    To generate a secure string from plain text, use:
    $F5Password = ConvertTo-SecureString -String $Password -AsPlainText -Force  
#>
    param(
        [Parameter(Mandatory=$true)][string]$LTMName,
        [Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$LTMCredentials
    )

    $BaseURL = "https://$LTMName/mgmt/tm/ltm/"

    #Create custom credential object for connecting to REST API
    [pscustomobject]@{BaseURL = $BaseURL; Credential = $LTMCredentials}

}



Function Test-Functionality{
<#
.SYNOPSIS
    Perform some standard tests to make sure things work as expected
.EXAMPLE
    Test-Functionality -F5Session $f5 -TestVirtualServer 'virt123' -TestVirtualServerIP '10.1.1.240' -TestPool 'testpool123' -PoolMember 'Server1'
#>
    param (
        [Parameter(Mandatory=$true)]$F5Session,
        [Parameter(Mandatory=$true)]$TestVirtualServer,
        [Parameter(Mandatory=$true)]$TestVirtualServerIP,
        [Parameter(Mandatory=$true)]$TestPool,
        [Parameter(Mandatory=$true)]$PoolMember
    )

    $TestNotesColor = 'Cyan'

    Write-Host "-----`r`nBeginning test`r`n-----" -ForegroundColor $TestNotesColor

    Write-Host "* Get the failover status of the F5 device" -ForegroundColor $TestNotesColor
    Get-F5Status -F5session $F5session

    Write-Host "`r`n* Get a list of all pools" -ForegroundColor $TestNotesColor
    Get-PoolList -F5session $F5Session
    
    $pools = Get-PoolList -F5session $F5Session
    Write-Host ("`r`n* Test whether the first pool in the list - " + $pools[0] + " - exists") -ForegroundColor $TestNotesColor
    Test-Pool -F5session $F5Session -PoolName $pools[0]

    Write-Host ("`r`n* Get the pool " + $pools[0]) -ForegroundColor $TestNotesColor
    Get-Pool -F5session $F5Session -PoolName $pools[0]

    Write-Host ("`r`n* Get members of the pool '" + $pools[0] + "'") -ForegroundColor $TestNotesColor
    Get-PoolMemberCollection -F5session $F5Session -PoolName $pools[0]

    Write-Host ("`r`n* Get the status of all members in the " + $pools[0] + " pool") -ForegroundColor $TestNotesColor
    Get-PoolMemberCollectionStatus -F5session $F5Session -PoolName $pools[0]

    Write-Host "`r`n* Create a new pool named '$TestPool'" -ForegroundColor $TestNotesColor
    New-Pool -F5session $F5Session -PoolName $TestPool 

    Write-Host "`r`n* Add the computer $PoolMember to the pool '$TestPool'" -ForegroundColor $TestNotesColor
    Add-PoolMember -F5session $F5session -ComputerName $PoolMember -PortNumber 80 -PoolName $TestPool -Status Enabled

    Write-Host "`r`n* Get the new pool member" -ForegroundColor $TestNotesColor
    Get-PoolMember -F5session $F5session -ComputerName $PoolMember -PoolName $TestPool

    Write-Host "`r`n* Get the IP address for the new pool member" -ForegroundColor $TestNotesColor
    Get-PoolMemberIP -F5Session $F5Session -ComputerName $PoolMember -PoolName $TestPool

    Write-Host "`r`n* Get all pools of which this pool member is a member" -ForegroundColor $TestNotesColor
    Get-PoolsForMember -F5session $F5Session -ComputerName $PoolMember

    Write-Host "`r`n* Get the number of current connections for this pool member" -ForegroundColor $TestNotesColor
    Get-CurrentConnectionCount -F5session $F5Session -ComputerName $PoolMember -PoolName $TestPool

    Write-Host "`r`n* Disable the new pool member" -ForegroundColor $TestNotesColor
    Disable-PoolMember -F5session $F5session -ComputerName $PoolMember
    
    Write-Host "`r`n* Get the status of the new pool member" -ForegroundColor $TestNotesColor
    $PoolMemberStatus = Get-PoolMemberStatus -F5session $F5session -ComputerName $PoolMember -PoolName $TestPool
    $PoolMemberStatus

    Write-Host "`r`n* Set the pool member description to 'My new pool' and retrieve it" -ForegroundColor $TestNotesColor
    Write-Host "Old description:"
    Get-PoolMemberDescription -F5Session $F5session -ComputerName $PoolMember -PoolName $TestPool
    Set-PoolMemberDescription -ComputerName $PoolMember -PoolName $TestPool -Description 'My new pool' -F5Session $F5session | out-null
    Write-Host "New description:"
    Get-PoolMemberDescription -F5Session $F5session -ComputerName $PoolMember -PoolName $TestPool

    Write-Host "`r`n* Enable the new pool member" -ForegroundColor $TestNotesColor
    Enable-PoolMember -F5session $F5session -ComputerName $PoolMember

    Write-Host "`r`n* Remove the new pool member from the pool" -ForegroundColor $TestNotesColor
    Remove-PoolMember -F5session $F5session -ComputerName $PoolMember -PortNumber 80 -PoolName $TestPool

    Write-Host "`r`n* Get a list of all virtual servers" -ForegroundColor $TestNotesColor
    Get-VirtualServerList -F5Session $F5Session
    
    $virtualServers = Get-VirtualServerList -F5Session $F5Session
    Write-Host ("`r`n* Test whether the first virtual server in the list - " +  $virtualServers[0] + " - exists") -ForegroundColor $TestNotesColor
    Test-VirtualServer -F5Session $F5Session -VirtualServerName $virtualServers[0]

    Write-Host ("`r`n* Get the virtual server '" + $virtualServers[0] + "'") -ForegroundColor $TestNotesColor
    Get-VirtualServer -F5Session $F5Session -VirtualServerName $virtualServers[0]

    Write-Host "`r`n* Create a new virtual server named '$TestVirtualServer'" -ForegroundColor $TestNotesColor
    New-VirtualServer -F5Session $F5Session -VirtualServerName $TestVirtualServer -Description 'description' -DestinationIP $TestVirtualServerIP -DestinationPort '80' -DefaultPool $TestPool -IPProtocol 'tcp' -ProfileNames 'http'

    Write-Host ("`r`n* Retrieve all iRules on the F5 LTM device.") -ForegroundColor $TestNotesColor
    $iRules = Get-iRuleCollection -F5session $F5Session
    Write-Output ("- This can be a large collection. The first entry found is:")
    Write-Output $iRules[0]

    Write-Host ("`r`n* Add the iRule '" + $iRules[0].name + "' to the new virtual server '$TestVirtualServer'") -ForegroundColor $TestNotesColor
    Add-iRuleToVirtualServer -F5session $F5Session -VirtualServer $TestVirtualServer -iRuleName $($iRules[0].name)

    Write-Host "`r`n* Get all iRules assigned to '$TestVirtualServer'" -ForegroundColor $TestNotesColor
    Get-VirtualServeriRuleCollection -F5session $F5Session -VirtualServer  $TestVirtualServer 

    Write-Host ("`r`n* Remove the '" + $iRules[0].name + "' iRule from the new virtual server '$TestVirtualServer'") -ForegroundColor $TestNotesColor
    Remove-iRuleFromVirtualServer -F5session $F5Session -VirtualServer $TestVirtualServer -iRuleName $iRules[0].name

    Write-Host "`r`n* Remove the new virtual server '$TestVirtualServer'" -ForegroundColor $TestNotesColor
    Write-Host "(This will raise a confirmation prompt unless -confirm is set to false)" -ForegroundColor $TestNotesColor
    Remove-VirtualServer -F5session $F5Session -VirtualServerName $TestVirtualServer
    
    Write-Host "`r`n* Remove the new pool '$TestPool'" -ForegroundColor $TestNotesColor
    Write-Host "(This will raise a confirmation prompt unless -confirm is set to false)" -ForegroundColor $TestNotesColor
    Remove-Pool -F5session $F5Session -PoolName $TestPool 

    Write-Host "-----`r`nTest complete`r`n-----" -ForegroundColor $TestNotesColor

}


Function Invoke-RestMethodOverride {
    param ( 
        [Parameter(Mandatory=$true)][string]$Method,
        [Parameter(Mandatory=$true)][string]$URI,
        [Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$Credential,
        $Body=$null,
        $Headers=$null,
        $ContentType=$null
    )

    [SSLValidator]::OverrideValidation()

    Invoke-RestMethod -Method $Method -Uri $URI -Credential $Credential -Body $Body -Headers $Headers -ContentType $ContentType 

    [SSLValidator]::RestoreValidation()

}


Function Get-F5Status{
<#
.SYNOPSIS                                                                          
    Test whether the specified F5 is currently in active or standby failover mode
#>
    param (
        [Parameter(Mandatory=$true)]$F5session
    )

    $FailoverPage = $F5Session.BaseURL -replace "/ltm/", "/cm/failover-status"

    $FailoverJSON = Invoke-RestMethodOverride -Method Get -Uri $FailoverPage -Credential $F5Session.Credential

    #This is where the failover status is indicated
    $FailOverStatus = $FailoverJSON.entries.'https://localhost/mgmt/tm/cm/failover-status/0'.nestedStats.entries.status.description

    #Return the failover status value
    $FailOverStatus

}

Function Sync-DeviceToGroup{
<#
.SYNOPSIS
    Sync the specified device to the group. This assumes the F5 session object is for the device that will be synced to the group.
#>
    param (
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$GroupName
    )
    
    $URI = $F5session.BaseURL -replace "/ltm", "/cm"

    $JSONBody = @{command='run';utilCmdArgs="config-sync to-group $GroupName"}
    $JSONBody = $JSONBody | ConvertTo-Json

    Try{
        $response = Invoke-RestMethodOverride -Method POST -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ContentType 'application/json'
        Write-Output $true

    }
    Catch {
        Write-Error ("Failed to sync the device to the $GroupName group")
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

}


Function Get-VirtualServerList{
<#
.SYNOPSIS
    Get a list of all virtual servers for the specified F5 LTM
#>
    
    param (
        [Parameter(Mandatory=$true)]$F5session
    )

    #Only retrieve the pool names
    $VirtualServersPage = $F5session.BaseURL + 'virtual?$select=name'

    Try {
        $VirtualServersJSON = Invoke-RestMethodOverride -Method Get -Uri $VirtualServersPage -Credential $F5session.Credential
        $VirtualServersJSON.items.name

    }
    Catch{

        Write-Error ("Failed to retrieve the list of virtual servers.")
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

}


Function Get-VirtualServer{
<#
.SYNOPSIS
    Retrieve the specified virtual server
#>

    param (
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)][string]$VirtualServerName
    )

    Write-Verbose "NB: Virtual server names are case-specific."

    #Build the URI for this virtual server
    $URI = $F5session.BaseURL + "virtual/$VirtualServerName"

    Try {
        Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5session.Credential
    }
    Catch{

        Write-Error ("Failed to retrieve the $VirtualServerName virtual server.")
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

}

Function Test-VirtualServer { 
<#
.SYNOPSIS
    Test whether the specified virtual server exists
.NOTES
    Pool names are case-specific.
#>
    
    param (
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)][string]$VirtualServerName
    )

    Write-Verbose "NB: Virtual server names are case-specific."

    #Build the URI for this virtual server
    $URI = $F5session.BaseURL + "virtual/$VirtualServerName"

    Try {
        Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5session.Credential | out-null
        $true
    }
    Catch{
        $false
    }

}

Function New-VirtualServer{
<#
.SYNOPSIS
    Create a new virtual server
#>
    param (
        [Parameter(Mandatory=$true)]$F5session,
        $Kind="tm:ltm:virtual:virtualstate",
        [Parameter(Mandatory=$true)][string]$VirtualServerName,
        $Description=$null,
        [Parameter(Mandatory=$true)]$DestinationIP,
        [Parameter(Mandatory=$true)]$DestinationPort,
        $Source='0.0.0.0/0',
        $DefaultPool=$null,
        [string[]]$ProfileNames=$null,
        [Parameter(Mandatory=$true,ParameterSetName = 'IpProtocol')]
        [ValidateSet("tcp","udp","sctp")]
        $ipProtocol=$null,
        $Mask='255.255.255.255',
        $ConnectionLimit='0'
    )
    
    $URI = ($F5session.BaseURL + "virtual")

    #Check whether the specified virtual server already exists
    If (Test-VirtualServer -F5session $F5session -VirtualServerName $VirtualServerName){
        Write-Error "The $VirtualServerName pool already exists."
    }

    Else {

        #Start building the JSON for the action
        $Destination = $DestinationIP + ":" + $DestinationPort
        $JSONBody = @{kind=$Kind;name=$VirtualServerName;description=$Description;partition='Common';destination=$Destination;source=$Source;pool=$DefaultPool;ipProtocol=$ipProtocol;mask=$Mask;connectionLimit=$ConnectionLimit}

        #Build array of profile items
        #JN: What happens if a non-existent profile is passed in?
        $ProfileItems = @()
        ForEach ($ProfileName in $ProfileNames){
            $ProfileItems += @{kind='tm:ltm:virtual:profiles:profilesstate';name=$ProfileName}
        }
        $JSONBody.profiles = $ProfileItems

        $JSONBody = $JSONBody | ConvertTo-Json

        Write-Verbose $JSONBody

        Try{
            Invoke-RestMethodOverride -Method POST -Uri "$URI" -Credential $F5Session.Credential -Body $JSONBody -ContentType 'application/json'
        }
        Catch {
            Write-Error ("Failed to retrieve the $VirtualServerName virtual server.")
            Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
            Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
        }

    }

}

Function Remove-VirtualServer{
<#
.SYNOPSIS
    Remove the specified virtual server. Confirmation is needed.
.NOTES
    Virtual server names are case-specific.
#>
    [CmdletBinding( SupportsShouldProcess=$true, ConfirmImpact="High")]    

    param (
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)][string]$VirtualServerName
        
    )

    Write-Verbose "NB: Virtual server names are case-specific."

    #Build the URI for this pool
    $URI = $F5session.BaseURL + "virtual/$VirtualServerName"

    if ($pscmdlet.ShouldProcess($VirtualServerName)){

        #Check whether the specified virtual server exists
        If (!(Test-VirtualServer -F5session $F5session -VirtualServerName $VirtualServerName)){
            Write-Error "The $VirtualServerName virtual server does not exist."
        }

        Else {
  
            Try {
                $response = Invoke-RestMethodOverride -Method DELETE -Uri "$URI" -Credential $F5session.Credential -ContentType 'application/json'
                Write-Output $true
            }
            Catch {
                Write-Error ("Failed to remove the $VirtualServerName virtual server.")
                Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
                Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)            
            }
        }
    }

}

Function Get-PoolList {
<#
.SYNOPSIS
    Get a list of all pools for the specified F5 LTM
#>
    param (
        [Parameter(Mandatory=$true)]$F5session
    )

    #Only retrieve the pool names
    $PoolsPage = $F5session.BaseURL + 'pool/?$select=name'

    Try {

        $PoolsJSON = Invoke-RestMethodOverride -Method Get -Uri $PoolsPage -Credential $F5session.Credential
        $PoolsJSON.items.name

    }
    Catch{
        Write-Error ("Failed to get the list of pool names.")
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }
}

Function Get-Pool {
<#
.SYNOPSIS
    Retrieve the specified pool
.NOTES
    Pool names are case-specific.
#>
   
    param (
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)][string]$PoolName
    )

    Write-Verbose "NB: Pool names are case-specific."

    #Build the URI for this pool
    $URI = $F5session.BaseURL + "pool/$PoolName"

    Try {
        Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5session.Credential -ErrorAction SilentlyContinue
    }
    Catch{
        Write-Error ("Failed to get the $PoolName pool.")
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

}

Function Test-Pool {
<#
.SYNOPSIS
    Test whether the specified pool exists
.NOTES
    Pool names are case-specific.
#>
    param (
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)][string]$PoolName
    )

    Write-Verbose "NB: Pool names are case-specific."

    #Build the URI for this pool
    $URI = $F5session.BaseURL + "pool/$PoolName"

    Try {
        Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5session.Credential -ErrorAction SilentlyContinue | out-null
        $true
    }
    Catch {
        $false
    }

}

Function New-Pool {
<#
.SYNOPSIS
    Create a new pool. Optionally, add pool members to the new pool

.DESCRIPTION
    Expects the $MemberDefinitionList param to be an array of strings. 
    Each string should contain a computer name and a port number, comma-separated.
    Optionally, it can contain a description of the member.

.EXAMPLE
    New-Pool -F5Session $F5Session -PoolName "MyPoolName" -MemberDefinitionList @("Server1,80,Web server","Server2,443,Another web server")

#>   
    param (
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)][string]$PoolName,
        [string[]]$MemberDefinitionList=$null
    )


    $URI = ($F5session.BaseURL + "pool")

    #Check whether the specified pool already exists
    If (Test-Pool -F5session $F5session -PoolName $PoolName){
        Write-Error "The $PoolName pool already exists."
    }

    Else {

        #Start building the JSON for the action
        $JSONBody = @{name=$PoolName;partition='Common';members=@()}

        $Members = @()

        ForEach ($MemberDefinition in $MemberDefinitionList){

            #Build the member name from the IP address and the port
            $MemberObject = $MemberDefinition.Split(",")

            If ($MemberObject.Length -lt 2){
                Throw("All member definitions should consist of a string containing at least a computer name and a port, comma-separated.")
            }

            $IPAddress = Get-CimInstance -ComputerName $MemberObject[0] -Class Win32_NetworkAdapterConfiguration | Where-Object DefaultIPGateway | Select-Object -exp IPaddress | Select-Object -first 1

            Try {
                $PortNumber = [int]$MemberObject[1]
            }
            Catch {
                $ThrowMessage = $MemberObject[1] + " is not a valid value for a port number."
                Throw($ThrowMessage)
            }

            If (($PortNumber -lt 0) -or ($PortNumber -gt 65535)){
                $ThrowMessage = $MemberObject[1] + " is not a valid value for a port number."
                Throw($ThrowMessage)
            }

            $Member = @{name=$($IPAddress + ":" + $PortNumber);address=$IPAddress;description=$($MemberObject[2])}
            $Members += $Member

        }

        $JSONBody.members = $Members
        $JSONBody = $JSONBody | ConvertTo-Json


        Try {
            $response = Invoke-RestMethodOverride -Method POST -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody -Headers @{"Content-Type"="application/json"}
            $true
        }
        Catch{
            Write-Error ("Failed to create the $PoolName pool.")
            Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
            Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
        }

    }

}

Function Remove-Pool{
<#
.SYNOPSIS
    Remove the specified pool. Confirmation is needed
.NOTES
    Pool names are case-specific.
#>
    
    [CmdletBinding( SupportsShouldProcess=$true, ConfirmImpact="High")]    

    param (
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)][string]$PoolName
        
    )

    #Build the URI for this pool
    $URI = $F5session.BaseURL + "pool/$PoolName"

    if ($pscmdlet.ShouldProcess($PoolName)){

        #Check whether the specified pool already exists
        If (!(Test-Pool -F5session $F5session -PoolName $PoolName)){
            Write-Error "The $PoolName pool does not exist.`r`nNB: Pool names are case-specific."
        }

        Else {
  
            Try {
                $response = Invoke-RestMethodOverride -Method DELETE -Uri "$URI" -Credential $F5session.Credential -ContentType 'application/json'
                Write-Output $true
            }
            Catch {
                Write-Error "Failed to remove the $PoolName pool."
                Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
                Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
                Return($false)
            }

        }
    }

}


Function Get-PoolMemberCollection {
<#
.SYNOPSIS
    Get the members of the specified pool
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$PoolName
    )

    $PoolMembersPage = $F5session.BaseURL + "pool/~Common~$PoolName/members/?"

    Try {
        $PoolMembersJSON = Invoke-RestMethodOverride -Method Get -Uri $PoolMembersPage -Credential $F5session.Credential
        $PoolMembersJSON.items
    }
    Catch {
        Write-Error "Failed to get the members of the $PoolName pool."
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }


}

Function Get-PoolMemberCollectionStatus {
<#
.SYNOPSIS
    Get the status of all members of the specified pool
#>
    param(
        [Parameter(Mandatory=$true)]$PoolName,
        [Parameter(Mandatory=$true)]$F5session
    )

    $PoolMembers = Get-PoolMemberCollection -PoolName $PoolName -F5session $F5session | Select-Object -Property name,session,state

    $PoolMembers
}

Function Get-PoolMember {
<#
.SYNOPSIS
    Get details about the specified pool member
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName
    )

    $PoolMember = $null

    $IPAddress = Get-PoolMemberIP -F5Session $F5session -ComputerName $ComputerName -PoolName $PoolName

    $PoolMemberURI = $F5session.BaseURL + "pool/~Common~$PoolName/members/~Common~$IPAddress`?"

    Try {
        $PoolMemberJSON = Invoke-RestMethodOverride -Method Get -Uri $PoolMemberURI -Credential $F5session.Credential
        $PoolMemberJSON
    }
    Catch {
        Write-Error "Failed to get the details for the pool member $ComputerName in the $PoolName pool."
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }
    
    $PoolMember

}

Function Get-PoolMemberDescription {
<#
.SYNOPSIS
    Get the current session and state values for the specified computer
#>
    param(
        [Parameter(Mandatory=$true)]$F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName
    )

    $PoolMember = Get-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolName

    $PoolMember = $PoolMember | Select-Object -Property name,description

    $PoolMember.description
}

Function Set-PoolMemberDescription {
<#
.SYNOPSIS
    Set the description value for the specified pool member
#>
    param(
        [Parameter(Mandatory=$true)]$F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName,
        [Parameter(Mandatory=$true)]$Description
    )

    $IPAddress = Get-PoolMemberIP -ComputerName $ComputerName -PoolName $PoolName -F5Session $F5session

    $URI = $F5session.BaseURL + "pool/~Common~$PoolName/members/$IPAddress"

    $JSONBody = @{description=$Description} | ConvertTo-Json

    Try {
        $response = Invoke-RestMethodOverride -Method PUT -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody -ContentType 'application/json'
        $true
    }
    Catch {
        Write-Error "Failed to set the description on $ComputerName in the $PoolName pool to $Description."
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

}

Function Get-PoolMemberStatus {
<#
.SYNOPSIS
    Get the current session and state values for the specified computer for the specified pool
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName
    )

    $PoolMember = Get-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolName

    $PoolMember = $PoolMember | Select-Object -Property name,session,state

    $PoolMember 
}

Function Get-PoolsForMember {
<#
.SYNOPSIS
    Determine which pool(s) a server is in
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$ComputerName
    )

    #All servers that are LTM pool members use the NIC with a default gateway as the IP that registers with the LTM
    $ComputerIP = Get-CimInstance -ComputerName $ComputerName -Class Win32_NetworkAdapterConfiguration | Where-Object DefaultIPGateway | Select-Object -exp IPaddress | Select-Object -first 1
    
    $AllPools = Get-PoolList -F5session $F5session

    $PoolsFound = @()

    foreach($Pool in $AllPools) 
    {
        $PoolMembers = Get-PoolMemberCollection -PoolName $Pool -F5session $F5session

        foreach($PoolMember in $PoolMembers) {

            if($PoolMember.address -eq $ComputerIP) {
                $PoolsFound += $Pool
            }
        }

    }

    $PoolsFound
}

Function Get-PoolMemberIP {
<#
.SYNOPSIS
    Determine the IP address and port for a server in a particular pool
#>
    param(
        [Parameter(Mandatory=$true)]$F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName
    )

    $IPAddress = Get-CimInstance -ComputerName $ComputerName -Class Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue | Where-Object DefaultIPGateway | Select-Object -exp IPaddress | Select-Object -first 1
    #If we don't get an IP address for the computer, then fail
    If (!($IPAddress)){
        Write-Error "Failed to obtain IP address for $ComputerName. The error returned was:`r`n$Error[0]"
        Return($false)
    }

    #Check the members of the specified pool to see if there is a member that matches this computer's IP address
    $PoolMembers = Get-PoolMemberCollection -PoolName $PoolName -F5session $F5Session     
    $MemberName = $false
    foreach($PoolMember in $PoolMembers) {

        if($PoolMember.address -eq $IPAddress) {
            $MemberName = $PoolMember.Name
        }
    }

    If ($MemberName){
        Return($MemberName)
    }
    Else {
        Write-Error "This computer was not found in the specified pool."
        Return($false)
    }

}


Function Add-PoolMember{
<#
.SYNOPSIS
    Add a computer to a pool as a member
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PortNumber,
        [Parameter(Mandatory=$true)]$PoolName,
        [ValidateSet("Enabled","Disabled")]
        [Parameter(Mandatory=$true)]$Status
    )

    $URI = $F5session.BaseURL + "pool/~Common~$PoolName/members"
    
    $IPAddress = Get-CimInstance -ComputerName $ComputerName -Class Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue | Where-Object DefaultIPGateway | Select-Object -exp IPaddress | Select-Object -first 1

    #If we don't get an IP address for the computer, then fail
    If (!($IPAddress)){
        Write-Error "Failed to obtain IP address for $ComputerName. The error returned was:`r`n$Error[0]"
        Return($false)
    }

    $MemberName = $IPAddress + ":" + $PortNumber

    $JSONBody = @{name=$MemberName;address=$IPAddress;description=$ComputerName} | ConvertTo-Json

    Try {
        Invoke-RestMethodOverride -Method POST -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorAction SilentlyContinue
    }
    Catch {
        Write-Error "Failed to add $ComputerName to $PoolName."
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }


    #After adding to the pool, make sure the member status is set as specified
    If ($Status -eq "Enabled"){
        Enable-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolName 
    }
    ElseIf ($Status -eq "Disabled"){
        Disable-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolName 
    }
}


Function Remove-PoolMember{
<#
.SYNOPSIS
    Remove a computer from a pool
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PortNumber,
        [Parameter(Mandatory=$true)]$PoolName
    )

    $IPAddress = Get-CimInstance -ComputerName $ComputerName -Class Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue | Where-Object DefaultIPGateway | Select-Object -exp IPaddress | Select-Object -first 1
    #If we don't get an IP address for the computer, then fail
    If (!($IPAddress)){
        Write-Error "Failed to obtain IP address for $ComputerName. The error returned was:`r`n$Error[0]"
        Return($false)
    }
    
    $MemberName = $IPAddress + ":" + $PortNumber

    $URI = $F5session.BaseURL + "pool/~Common~$PoolName/members/~Common~$MemberName"
    
    Try {
        $response = Invoke-RestMethodOverride -Method DELETE -Uri "$URI" -Credential $F5session.Credential -ContentType 'application/json' -ErrorAction SilentlyContinue
        $true
    }
    Catch {
        Write-Error "Failed to remove $ComputerName from $PoolName."
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

}


Function Disable-PoolMember{
<#
.SYNOPSIS
    Disable a pool member in the specified pools
    If no pool is specified, the member will be disabled in all pools
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$ComputerName,
        $PoolName=$null,
        [switch]$Force
    )

    #If the -Force param is specified pool members do not accept any new connections, even if they match an existing persistence session.
    #Otherwise, members will only accept only new connections that match an existing persistence session.
    If ($Force){
        $AcceptNewConnections = "user-down"
    }
    Else {
        $AcceptNewConnections = "user-up"
    }

    $JSONBody = @{state=$AcceptNewConnections;session='user-disabled'} | ConvertTo-Json

    #If a pool name is passed in, verify the pool exists and disable the member in that pool only
    If ($PoolName){

        If (Test-Pool -F5session $F5session -PoolName $PoolName){

            $MemberFullName = (Get-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolName).Name
 
            $URI = $F5session.BaseURL + "pool/~Common~$PoolName/members/$MemberFullName"

            Try {
                $response = Invoke-RestMethod -Method Put -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody
                $true
            }
            Catch {
                Write-Error "Failed to disable $ComputerName in the $PoolName pool."
                Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
                Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
            }
        }
        Else {
            Write-Verbose "Pool $PoolName not found"
            Return($false)
        }
    }

    #Otherwise, disable the member in all their pools
    Else {

        $Pools = Get-PoolsForMember -ComputerName $ComputerName -F5session $F5session

        ForEach ($PoolName in $Pools){
    
            $MemberFullName = (Get-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolName).Name

            $URI = $F5session.BaseURL + "pool/~Common~$PoolName/members/$MemberFullName"

            Try {
                $response = Invoke-RestMethodOverride -Method Put -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody
            }
            Catch {
                Write-Error "Failed to disable $ComputerName in the $PoolName pool."
                Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
                Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
                Return($false)
            }

        }
        $true
    }    
}


Function Enable-PoolMember {
<#
.SYNOPSIS
    Enable a pool member in the specified pools
    If no pool is specified, the member will be disabled in all pools
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$ComputerName,
        $PoolName=$null
    )

    $JSONBody = @{state='user-up';session='user-enabled'} | ConvertTo-Json

    #If a pool name is passed in, verify the pool exists and enable the member in that pool only
    If ($PoolName){

        If (Test-Pool -F5session $F5session -PoolName $PoolName){

            $MemberFullName = (Get-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolName).Name

            $URI = $F5session.BaseURL + "pool/~Common~$PoolName/members/$MemberFullName"

            Try {
                $response = Invoke-RestMethodOverride -Method Put -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody
                $true
            }
            Catch {
                Write-Error "Failed to enable $ComputerName in the $PoolName pool."
                Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
                Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
            }
        }

        Else {
            Write-Verbose "Pool $PoolName not found"
            Return($false)
        }

    }

    #Otherwise, enable the member in all their pools
    Else {

        $Pools = Get-PoolsForMember -ComputerName $ComputerName -F5session $F5session

        ForEach ($PoolName in $Pools){
    
            $MemberFullName = (Get-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolName).Name

            $URI = $F5session.BaseURL + "pool/~Common~$PoolName/members/$MemberFullName"

            Try {
                $response = Invoke-RestMethodOverride -Method Put -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody
            }
            Catch {
                Write-Error "Failed to disable $ComputerName in the $PoolName pool."
                Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
                Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
                Return($false)
            }

        }
        $true
    } 

}

Function Get-CurrentConnectionCount {
<#
.SYNOPSIS
    Get the count of the specified pool member's current connections
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName
    )

    $IPAddress = (Get-PoolMember -F5session $F5session -ComputerName $ComputerName -PoolName $PoolName).Name

    $PoolMember = $F5session.BaseURL + "pool/~Common~$PoolName/members/~Common~$IPAddress/stats"

    $PoolMemberJSON = Invoke-RestMethodOverride -Method Get -Uri $PoolMember -Credential $F5session.Credential

    #Return the number of current connections for this member of this pool
    $PoolMemberJSON.entries.'serverside.curConns'.value

}

Function Get-StatusShape {
<#
.SYNOPSIS
    Determine the shape to display for a member's current state and session values
#>
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

Function Get-iRuleCollection {
<#
.SYNOPSIS
    Get all iRules for the specified F5 LTM device
#>
    param(
        [Parameter(Mandatory=$true)]$F5session
    )

    $iRuleURL = $F5session.BaseURL + "rule/"

    Try {
        $iRulesJSON = Invoke-RestMethodOverride -Method Get -Uri $iRuleURL -Credential $F5session.Credential
        $iRulesJSON.items
    }
    Catch {
        Write-Error "Failed to get the list of iRules for the LTM device."
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

}

Function Get-VirtualServeriRuleCollection {
<#
.SYNOPSIS
    Get the iRules currently applied to the specified virtual server   
.NOTES
    This function assumes everything is in the /Common partition
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$VirtualServer
    )

    $VirtualServerURI = $F5session.BaseURL + "virtual/~Common~$VirtualServer/"

    Try {
        $VirtualserverObject = Invoke-RestMethodOverride -Method Get -Uri $VirtualServerURI -Credential $F5session.Credential
    }
    Catch {
        Write-Error "Failed to get the list of iRules for the $VirtualServer virtual server."
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
        return $false
    }

    #Filter the content for just the iRules
    $VirtualserverObjectContent = $VirtualserverObject | Select-Object -Property rules

    $iRules = $VirtualserverObjectContent.rules

    #If the existing iRules collection is not an array, then convert it to one before returning
    If ($iRules -isnot [system.array]){
        $iRulesArray = @()
        $iRulesArray += $iRules
    }
    Else {
        $iRulesArray = $iRules
    }

    $iRulesArray
}

Function Add-iRuleToVirtualServer {
<#
.SYNOPSIS
    Add an iRule to the specified virtual server
.NOTES
    This function assumes everything is in the /Common partition
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$VirtualServer,
        [Parameter(Mandatory=$true)]$iRuleName
    )

    $iRuleToAdd = "/Common/$iRuleName"

    #Verify that the iRule exists on the F5 LTM
    $AlliRules = Get-iRuleCollection -F5session $F5session
    If ($AlliRules.name -notcontains $iRuleName){
        Write-Warning "The $iRuleName iRule does not exist in this F5 LTM."
        Return($false)
    }

    #Verify that this virtual server exists
    If (!(Test-VirtualServer -F5session $F5session -VirtualServerName $VirtualServer)){
        Write-Warning "The $VirtualServer virtual server does not exist."
        Return($false)
    }

    #Get the existing IRules on the virtual server
    [array]$iRules = Get-VirtualServeriRuleCollection -VirtualServer $VirtualServer -F5session $F5session

    #If there are no iRules on this virtual server, then create a new array
    If (!$iRules){
        $iRules = @()
    }        

    #Check that the specified iRule is not already in the collection 
    If ($iRules -match $iRuleToAdd){
        Write-Warning "The $VirtualServer virtual server already contains the $iRuleName iRule."
        Return($false)
    }
    Else {
        $iRules += $iRuleToAdd

        $VirtualserverIRules = $F5session.BaseURL + "virtual/~Common~$VirtualServer/"

        $JSONBody = @{rules=$iRules} | ConvertTo-Json

        Try {
            $response = Invoke-RestMethodOverride -Method PUT -Uri "$VirtualserverIRules" -Credential $F5session.Credential -Body $JSONBody -Headers @{"Content-Type"="application/json"}
            $true
        }
        Catch {
            Write-Error "Failed to add the $iRuleName iRule to the $VirtualServer virtual server."
            Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
            Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
        }

    }

}

Function Remove-iRuleFromVirtualServer {
<#
.SYNOPSIS
    Remove an iRule from the specified virtual server
.NOTES
    This function assumes everything is in the /Common partition
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$VirtualServer,
        [Parameter(Mandatory=$true)]$iRuleName
    )

    $iRuleToRemove = "/Common/$iRuleName"

    #Get the existing IRules on the virtual server
    [array]$iRules = Get-VirtualServeriRuleCollection -VirtualServer $VirtualServer -F5session $F5session

    #If there are no iRules on this virtual server, then create a new array
    If (!$iRules){
        $iRules = @()
    }  

    #Check that the specified iRule is in the collection 
    If ($iRules -match $iRuleToRemove){

        $iRules = $iRules | Where-Object { $_ -ne $iRuleToRemove }

        $VirtualserverIRules = $F5session.BaseURL + "virtual/~Common~$VirtualServer/"

        $JSONBody = @{rules=$iRules} | ConvertTo-Json

        Try {
            $response = Invoke-RestMethodOverride -Method PUT -Uri "$VirtualserverIRules" -Credential $F5session.Credential -Body $JSONBody -Headers @{"Content-Type"="application/json"}
            $true
        }
        Catch {
            Write-Error "Failed to remove the $iRuleName iRule from the $VirtualServer virtual server."
            Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
            Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
        }

    }
    Else {
        Write-Warning "The $VirtualServer virtual server does not contain the $iRuleName iRule."
        $false
    }

}


Function Remove-ProfileRamCache{
<#
.SYNOPSIS
    Delete the contents of a RAM cache for the specified profile
.NOTES
    Example profile: "profile/http/ramcache"
#>
    param(
        [Parameter(Mandatory=$true)]$F5session,
        [Parameter(Mandatory=$true)]$ProfileName
    )

    $ProfileURL = $F5session.BaseURL +$ProfileName

    Try {
        $response = Invoke-RestMethodOverride -Method DELETE -Uri "$ProfileURL" -Credential $F5session.Credential
    }
    Catch {
        Write-Error "Failed to clear the ram cache for the $ProfileName profile."
        Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
        Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
    }

}

