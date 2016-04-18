Function Get-PoolsForMember {
<#
.SYNOPSIS
    Determine which pool(s) a server is in
#>
    [cmdletBinding()]
    param(
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias('PoolMember')]
        [PSObject]$InputObject,

        [Alias("ComputerName")]
        [Parameter(Mandatory=$false,ParameterSetName='Address')]
        [string]$Address='*'
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        if ($PSCmdLet.ParameterSetName -eq 'Address') {
            if ($Address -ne '*') {
                $ip = [IPAddress]::Any
                if ([IpAddress]::TryParse($Address,[ref]$ip)) {
                    $Address = $ip.IpAddressToString
                } else {
                    $ip = [string]([System.Net.Dns]::GetHostAddresses($Address).IPAddressToString)
                    #If we don't get an IP address for the computer, try the value specified
                    If ($ip) {
                        $Address = $ip
                    }
                }
            }
        }
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            Address {
                $pools = Get-Pool -F5Session $F5Session
                foreach ($pool in $pools) {
                    $members = $pool | Get-PoolMember -F5session $F5Session | Where-Object { $_.address -like $Address }
                    if ($members) {
                        $pool
                    }    
                }
            }
            InputObject {
                foreach($member in $InputObject) {
                    Get-PoolsForMember -F5Session $F5Session -Address $member.address 
                }
            }
        }
    }
}
