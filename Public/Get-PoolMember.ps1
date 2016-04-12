Function Get-PoolMember {
<#
.SYNOPSIS
    Get details about the specified pool member
#>
    [cmdletBinding(DefaultParameterSetName='InputObject')]
    param(
        $F5Session=$Script:F5Session,

        [Parameter(ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias('Pool')]
        [PSObject[]]$InputObject,
        
        [Parameter(Mandatory=$true,ParameterSetName='PoolName',ValueFromPipeline=$true)]
        [string[]]$PoolName,
        [Parameter(Mandatory=$false,ParameterSetName='PoolName')]
        [string]$Partition,

        [Alias("ComputerName")]
        [Parameter(Mandatory=$false)]
        [string]$Address='*',

        [Parameter(Mandatory=$false)]
        [string]$Name='*'
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
        Write-Verbose "NB: Pool names are case-specific."

        if ($PSCmdLet.ParameterSetName -eq 'InputObject') {
            if ($Address -ne '*') {
                $ip = [IPAddress]::Any
                if ([IpAddress]::TryParse($Address,[ref]$ip)) {
                    $Address = $ip.IpAddressToString
                } else {
                    $Address = [string]([System.Net.Dns]::GetHostAddresses($Address).IPAddressToString)
                    #If we don't get an IP address for the computer, then fail
                    If (!($Address)){
                        Write-Error "Failed to obtain IP address for $Address. The error returned was:`r`n$Error[0]"
                    }
                }
            }
        }
    }
    process {
        switch($PSCmdLet.ParameterSetName) {
            PoolName {
                foreach($pName in $PoolName) {
                    Get-Pool -F5Session $F5Session -PoolName $pName -Partition $Partition | Get-PoolMember -F5session $F5Session -Address $Address -Name $Name
                }
            }
            InputObject {
                if ($null -eq $InputObject) {
                    $InputObject = Get-Pool -F5Session $F5Session
                }
                foreach($pool in $InputObject) {
                    $MembersLink = $F5Session.GetLink($pool.membersReference.link)
                    $JSON = Invoke-RestMethodOverride -Method Get -Uri $MembersLink -Credential $F5Session.Credential
                    ($JSON.items,$JSON -ne $null)[0] | Where-Object { $_.address -like $Address -and $_.name -like $Name } | Add-ObjectDetail -TypeName 'PoshLTM.PoolMember'
                }
            }
        }
    }
}