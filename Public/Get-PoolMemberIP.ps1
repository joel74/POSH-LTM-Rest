Function Get-PoolMemberIP {
<#
.SYNOPSIS
    Determine the IP address and port for a server in a particular pool
#>
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)]$ComputerName,
        [Parameter(Mandatory=$true)]$PoolName
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

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
