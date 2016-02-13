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
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)][string]$PoolName,
        [Parameter(Mandatory=$false)][string[]]$MemberDefinitionList=$null
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $URI = ($F5session.BaseURL + "pool")

    #Check whether the specified pool already exists
    If (Test-Pool -F5session $F5session -PoolName $PoolName){
        Write-Error "The $PoolName pool already exists."
    }

    Else {
        $Partition = 'Common'
        if ($PoolName -match '^[/\\](?<Partition>[^/\\]*)[/\\](?<Name>[^/\\]*)$') {
            $Partition = $matches['Partition']
            $PoolName = $matches['Name']
        }
        #Start building the JSON for the action
        $JSONBody = @{name=$PoolName;partition=$Partition;members=@()}

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
            $response = Invoke-RestMethodOverride -Method POST -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody -ContentType 'application/json'
            $true
        }
        Catch{
            Write-Error ("Failed to create the $PoolName pool.")
            Write-Error ("StatusCode:" + $_.Exception.Response.StatusCode.value__)
            Write-Error ("StatusDescription:" + $_.Exception.Response.StatusDescription)
        }

    }

}
