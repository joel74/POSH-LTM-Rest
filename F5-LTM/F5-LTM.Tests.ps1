$scriptroot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Import-Module (Join-Path $scriptroot 'F5-LTM\F5-LTM.psm1') -Force

#$secpasswd = ConvertTo-SecureString "YourPassword" -AsPlainText -Force
$Config = Get-Content (Join-Path $HOME F5-LTM.json) | ConvertFrom-Json
function ConvertPSObjectToHashtable
{
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process
    {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject) { ConvertPSObjectToHashtable $object }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject])
        {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = ConvertPSObjectToHashtable $property.Value
            }

            $hash
        }
        else
        {
            $InputObject
        }
    }
}
function Set-FullPathAndPartition {
    param(
        [Parameter(Mandatory=$true)]
        $InputObject
    )
    begin {
        Function Set-FullPathAndPartitionInternal {
            param(
                [Parameter(Mandatory=$true)]
                $InputObject,
                $ParentPath,
                $Partition
            )
            process {
                foreach ($item in $InputObject) {
                    $fullPath = ($ParentPath,$item.name | Where-Object { $_ }) -join '/'
                    if ($item.Name) {
                        if ($item.name -notmatch ':\d+$') {
                            $item = $item | Add-Member -MemberType NoteProperty -Name fullPath -Value "/$fullPath" -PassThru
                        }
                        $item = $item | Add-Member -MemberType NoteProperty -Name partition -Value $Partition -PassThru
                    }
                    foreach ($prop in $item.PSObject.Properties) {
                        Set-FullPathAndPartitionInternal -InputObject $item."$($prop.Name)" -ParentPath $fullPath -Partition $Partition
                    }
                }
            }
        }
    }
    process {
        foreach ($item in $InputObject) {
            foreach ($prop in $item.PSObject.Properties) {
                if ($prop.Name -eq 'Partitions') {
                    foreach($partition in $item.Partitions) {
                        Set-FullPathAndPartitionInternal -InputObject $partition -Partition $partition.name
                    }
                } else {
                    Set-FullPathAndPartition -InputObject $item."$($prop.Name)"
                }
            }
        }
    }
}
Set-FullPathAndPartition -InputObject $Config

foreach ($session in $Config.Sessions) {
    $password = $session.Password | ConvertTo-SecureString
    $credentials = New-Object System.Management.Automation.PSCredential ($session.UserName, $password)
    New-F5Session -LTMName $session.LTMName -LTMCredentials $credentials -Default
    
    $HealthMonitorTestCases = @($session.Partitions.HealthMonitors | Where-Object { -not $_.addremove } | % { $_ | ConvertPSObjectToHashtable }) 
    $HealthMonitorTypeTestCases = @($session.HealthMonitorTypes | Where-Object { -not $_.addremove } | Where-Object { -not $_.addremove }  | % { $_ | ConvertPSObjectToHashtable }) 
    $iRuleTestCases = @($session.Partitions.iRules | Where-Object { -not $_.addremove } | % { $_ | ConvertPSObjectToHashtable })
    $PartitionTestCases = @($session.Partitions | Where-Object { -not $_.addremove } | % { $_ | ConvertPSObjectToHashtable })
    $PoolTestCases = @($session.Partitions.Pools | Where-Object { -not $_.addremove } | % { $_ | ConvertPSObjectToHashtable })
    $PoolMemberTestCases = @($session.Partitions.Pools.PoolMembers | Where-Object { -not $_.addremove } | % { $_ | ConvertPSObjectToHashtable })
    $PoolMonitorTestCases = @($session.Partitions.PoolMonitors | Where-Object { -not $_.addremove } | % { $_ | ConvertPSObjectToHashtable })
    $NodeTestCases = @($session.Partition.Nodes | Where-Object { -not $_.addremove } | % { $_ | ConvertPSObjectToHashtable })
    $VirtualServerTestCases = @($session.Partition.VirtualServers | Where-Object { -not $_.addremove } | % { $_ | ConvertPSObjectToHashtable })

    $TempNodeTestCases = @($session.Partitions.Nodes | Where-Object { $_.addremove } | % { $_ | ConvertPSObjectToHashtable })
    $TempPoolMemberTestCases = @($session.Partitions.Pools.PoolMembers | Where-Object { $_.addremove } | % { $_ | ConvertPSObjectToHashtable })

Describe "HealthMonitor" {
    Context "Get" {
        It "Gets health monitors *" {
            Get-HealthMonitor |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Not Be 0
        }
        It "Gets health monitors of type '<name>'" -TestCases $HealthMonitorTypeTestCases {
            param($Name)
            
            Get-HealthMonitor -Type $Name |
                Select-Object -ExpandProperty type | 
                Should Be $Name
        }
        It "Gets health monitors in partition '<name>'" -TestCases $PartitionTestCases {
            param($Name)
            
            Get-HealthMonitor -Partition $Name |
                Select-Object -ExpandProperty partition | 
                Should Be $Name
        }
#        It "Gets health monitors in partition '<partition>' by Name '<name>'" -TestCases $HealthMonitorTestCases {
#            param($Name,$Partition)
#            
#            Get-HealthMonitor -Name $Name -Partition $Partition |
#                Select-Object -ExpandProperty name | 
#                Should Be $Name
#        }
#        It "Gets health monitors by fullPath '<fullPath>'" -TestCases $HealthMonitorTestCases {
#            param($fullPath)
#            
#            Get-HealthMonitor -Name $fullPath |
#                Select-Object -ExpandProperty fullPath | 
#                Should Be $fullPath
#        }
        It "Gets health monitors by Name[]" {
            Get-HealthMonitor -Name ($session.Partitions.HealthMonitors | Where-Object { -not $_.addremove }).fullPath |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.HealthMonitors | Where-Object { $_ -and -not $_.addremove }).Count
        }
        It "Gets health monitors by Name ValueFromPipeline" {
            ($session.Partitions.HealthMonitors | Where-Object { $_ -and -not $_.addremove }).fullPath | 
                Get-HealthMonitor |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.HealthMonitors | Where-Object { $_ -and -not $_.addremove }).Count
        }
        It "Gets health monitors by Name,Partition ValueFromPipelineByPropertyName" {
            $session.Partitions.HealthMonitors | Where-Object { $_ -and -not $_.addremove } |
                Get-HealthMonitor |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.HealthMonitors | Where-Object { $_ -and -not $_.addremove }).Count
        }
    }
}
Describe "HealthMonitorType" {
    Context "Get" {
        It "Gets health monitor types *" {
            Get-HealthMonitorType |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Not Be 0
        }
        It "Gets health monitor types by Name '<name>'" -TestCases $HealthMonitorTypeTestCases {
            param($Name)
            
            Get-HealthMonitorType -Name $Name |
                Should Be $Name
        }
        It "Gets health monitor types by Name[]" {
            Get-HealthMonitorType -Name (($session.HealthMonitorTypes | Where-Object { -not $_.addremove }).name) |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be (($session.HealthMonitorTypes | Where-Object { -not $_.addremove }).Count)
        }
        It "Gets health monitor types by Name ValueFromPipeline" {
            ($session.HealthMonitorTypes | Where-Object { -not $_.addremove }).name | 
                Get-HealthMonitorType |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be (($session.HealthMonitorTypes | Where-Object { -not $_.addremove }).Count)
        }
        It "Gets health monitor types by Name ValueFromPipelineByPropertyName" {
            ($session.HealthMonitorTypes | Where-Object { -not $_.addremove }).name | 
                Get-HealthMonitorType |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.HealthMonitorTypes | Where-Object { -not $_.addremove }).Count
        }
    }
}
Describe "iRule" {
    Context "Get" {
        It "Gets irules *" {
            Get-iRule |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Not Be 0
        }
        It "Gets irules in partition '<name>'" -TestCases $PartitionTestCases {
            param($Name)
            
            Get-iRule -Partition $Name |
                Select-Object -ExpandProperty partition | 
                Should Be $Name
        }
        It "Gets irules in partition '<partition>' by Name '<name>'" -TestCases $iRuleTestCases {
            param($Name,$Partition)
            
            Get-iRule -Name $Name -Partition $Partition |
                Select-Object -ExpandProperty name | 
                Should Be $Name
        }
        It "Gets irules by fullPath '<fullPath>'" -TestCases $iRuleTestCases {
            param($fullPath)
            
            Get-iRule -Name $fullPath |
                Select-Object -ExpandProperty fullPath | 
                Should Be $fullPath
        }
        It "Gets irules by Name[]" {
            Get-iRule -Name (($session.Partitions.iRules | Where-Object { -not $_.addremove }).fullPath) |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.iRules | Where-Object { -not $_.addremove }).Count
        }
        It "Gets irules by Name ValueFromPipeline" {
            ($session.Partitions.iRules | Where-Object { -not $_.addremove }).fullPath | 
                Get-iRule |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.iRules | Where-Object { -not $_.addremove }).Count
        }
        It "Gets irules by Name,Partition ValueFromPipelineByPropertyName" {
            $session.Partitions.iRules | Where-Object { -not $_.addremove } |
                Get-iRule |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.iRules | Where-Object { -not $_.addremove }).Count
        }
    }
}
Describe "Node" {
    Context "Get" {
        It "Gets nodes *" {
            Get-Node |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Not Be 0
        }
        It "Gets nodes in partition '<name>'" -TestCases $PartitionTestCases {
            param($Name)
            
            Get-Node -Partition $Name |
                Select-Object -ExpandProperty partition | 
                Should Be $Name
        }
        It "Gets nodes in partition '<partition>' by Name '<name>'" -TestCases $NodeTestCases {
            param($Name,$Partition)
            
            Get-Node -Name $Name -Partition $Partition |
                Select-Object -ExpandProperty name | 
                Should Be $Name
        }
        It "Gets nodes by fullPath '<fullPath>'" -TestCases $NodeTestCases {
            param($fullPath)
            
            Get-Node -Name $fullPath |
                Select-Object -ExpandProperty fullPath | 
                Should Be $fullPath
        }
        It "Gets nodes by Name[]" {
            Get-Node -Name (($session.Partitions.Nodes | Where-Object { -not $_.addremove }).fullPath) |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.Nodes | Where-Object { -not $_.addremove }).Count
        }
        It "Gets nodes by Name ValueFromPipeline" {
            ($session.Partitions.Nodes | Where-Object { -not $_.addremove }).fullPath | 
                Get-Node |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.Nodes | Where-Object { -not $_.addremove }).Count
        }
        It "Gets nodes by Name,Partition ValueFromPipelineByPropertyName" {
            $session.Partitions.Nodes | Where-Object { -not $_.addremove } |
                Get-Node |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.Nodes | Where-Object { -not $_.addremove }).Count
        }
    }
    Context "Add" {
        It "Adds nodes by Address" -TestCases ($TempNodeTestCases | Select -First 1) {
            param($Partition,$Address)
            New-Node -Partition $Partition -Address $Address
        }
        It "Adds nodes by Address +Name" -TestCases ($TempNodeTestCases | Select -Last 1) {
            param($Partition,$Address,$Name)
            New-Node -Partition $Partition -Name $Name -Address $Address
        }
    }
    Context "Remove" {
        It "Removes node by Address" -TestCases ($TempNodeTestCases | Select -First 1) {
            param($Partition,$Address)
            Test-Node -Partition $Partition -Address $Address |
                Should Be True
            Remove-Node -Partition $Partition -Address $Address -Confirm:$false
            Test-Node -Partition $Partition -Address $Address |
                Should Be False
        }
        It "Removes node by Name" -TestCases ($TempNodeTestCases | Select -Last 1) {
            param($Partition,$Address,$Name)
            Test-Node -Partition $Partition -Name $Name |
                Should Be True
            Remove-Node -Partition $Partition -Name $Name -Confirm:$false
            Test-Node -Partition $Partition -Name $Name |
                Should Be False
        }
    }
}
Describe "Partition" {
    Context "Get" {
        It "Gets partitions *" {
            Get-Partition |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Not Be 0
        }
        It "Gets partitions by Name '<name>'" -TestCases $PartitionTestCases {
            param($Name)
            
            Get-Partition -Name $Name |
                Should Be $Name
        }
        It "Gets partitions by Name[]" {
            Get-Partition -Name $session.Partitions.name |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be $session.Partitions.Count
        }
        It "Gets partitions by Name ValueFromPipeline" {
            $session.Partitions.name | 
                Get-Partition |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be $session.Partitions.Count
        }
        It "Gets partitions by Name ValueFromPipelineByPropertyName" {
            $session.Partitions |
                Get-Partition |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be $session.Partitions.Count
        }
    }
}
Describe "Pool" {
    Context "Get" {
        It "Gets pools *" {
            Get-Pool |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Not Be 0
        }
        It "Gets pools in partition '<name>'" -TestCases $PartitionTestCases {
            param($Name)
            
            Get-Pool -Partition $Name |
                Select-Object -ExpandProperty partition | 
                Should Be $Name
        }
        It "Gets pools in partition '<partition>' by Name '<name>'" -TestCases $PoolTestCases {
            param($Name,$Partition)
            
            Get-Pool -Name $Name -Partition $Partition |
                Select-Object -ExpandProperty name | 
                Should Be $Name
        }
        It "Gets pools by fullPath '<fullPath>'" -TestCases $PoolTestCases {
            param($fullPath)
            
            Get-Pool -Name $fullPath |
                Select-Object -ExpandProperty fullPath | 
                Should Be $fullPath
        }
        It "Gets pools by Name[]" {
            Get-Pool -Name (($session.Partitions.Pools | Where-Object { -not $_.addremove }).fullPath) |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.Pools | Where-Object { -not $_.addremove }).Count
        }
        It "Gets pools by Name ValueFromPipeline" {
            ($session.Partitions.Pools | Where-Object { -not $_.addremove }).fullPath | 
                Get-Pool |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.Pools | Where-Object { -not $_.addremove }).Count
        }
        It "Gets pools by Name,Partition ValueFromPipelineByPropertyName" {
            $session.Partitions.Pools | Where-Object { -not $_.addremove } |
                Get-Pool |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.Pools | Where-Object { -not $_.addremove }).Count
        }
    }
}
Describe "PoolMember" {
    Context "Add" {
        It "Adds pool member by Address <poolname> <address> <port>" -TestCases ($TempPoolMemberTestCases | Select-Object -First 1) {
            param($PoolName,$Address,$Port)
            { Add-PoolMember -PoolName $PoolName -Status Disabled -Port $Port -Address $Address } |
                Should Not Throw
        }
        It "Adds pool member by ComputerName <poolname> <computername> <port>" -TestCases ($TempPoolMemberTestCases | Select-Object -Last 1) {
            param($PoolName,$ComputerName,$Port)
            { Add-PoolMember -PoolName $PoolName -Status Disabled -ComputerName $ComputerName -Name "$ComputerName`:$Port" -Port $Port } |
                Should Not Throw
        }
    }
    Context "Get" {
        It "Gets pool members *" {
            Get-PoolMember |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Not Be 0
        }
        It "Gets pool members in partition '<name>'" -TestCases $PartitionTestCases {
            param($Name)
            
            # Pool members can be from a different partition than the pool.  Check GetPoolName() partition matches instead.
            Get-PoolMember -Partition $Name |
                ForEach-Object { [Regex]::Match($_.GetPoolName(),'(?<=^/)[^/]*').Value } |
                Should Be $Name
        }
        It "Gets pool members in partition '<partition>' and pool '<name>'" -TestCases $PoolTestCases {
            param($Name,$Partition)

            # Pool members can be from a different partition than the pool.  Check GetPoolName() partition matches instead.
            Get-PoolMember -PoolName $Name -Partition $Partition |
                ForEach-Object { [Regex]::Match($_.GetPoolName(),'(?<=^/)[^/]*').Value } |
                Should Be $Partition
        }
        It "Gets pool members in pool '<fullPath>'" -TestCases $PoolTestCases {
            param($fullPath)
            
            Get-PoolMember -PoolName $fullPath |
                ForEach-Object { $_.GetPoolName() } |
                Should Be $fullPath
        }
        It "Gets pool members by Address[]" -TestCases $PoolMemberTestCases {
            param($PoolName,$Address)
            Get-Pool -PoolName $PoolName |
                Get-PoolMember -Address $Address |
                Select-Object -ExpandProperty Address | 
                Should Match '^\d+\.\d+\.\d+\.\d+'
        }
        It "Gets pool members by Name[]" -TestCases $PoolMemberTestCases {
            param($PoolName,$Name)
            Get-Pool -PoolName $PoolName |
                Get-PoolMember -Name $Name |
                Select-Object -ExpandProperty Name | 
                Should Match '^.+:\d+'
        }
    }
    Context "Remove" {
        It "Removes pool member by Address <poolname> <address>" -TestCases ($TempPoolMemberTestCases | Select-Object -First 1) {
            param($PoolName,$Partition,$Address)
            Remove-PoolMember -PoolName $PoolName -Address $Address -Confirm:$false
            # TODO: This raises the question: Should Remove-Poolmember remove the node?
            Remove-Node -Partition $Partition -Address $Address -Confirm:$false
        }
        It "Removes pool member by ComputerName <poolname> <name>" -TestCases ($TempPoolMemberTestCases | Select-Object -Last 1) {
            param($PoolName,$Partition,$Address,$Name)
            Remove-PoolMember -PoolName $PoolName -Name $Name -Confirm:$false
            Remove-Node -Partition $Partition -Address $Address -Confirm:$false
            #Remove-Node -Partition $Partition -Name $Name -Confirm:$false
        }
    }
}
Describe "PoolMemberStats" {
    Context "Get" {
        It "Gets pool member statistics in partition '<partition>' and pool '<name>'" -TestCases $PoolTestCases {
            param($Name,$Partition)

            Get-PoolMemberStats -PoolName $Name -Partition $Partition |
                Select-Object -ExpandProperty 'serverside.curConns' |
                Should Not Be Null
        }
        It "Gets pool member statistics in pool '<fullPath>'" -TestCases $PoolTestCases {
            param($fullPath)
            
            Get-PoolMemberStats -PoolName $fullPath |
                Select-Object -ExpandProperty 'serverside.curConns' |
                Should Not Be Null
        }
        It "Gets pool member statistics by Address[]" -TestCases $PoolMemberTestCases {
            param($PoolName,$Address)
            $memberstats = Get-Pool -PoolName $PoolName |
                Get-PoolMemberStats -Address $Address
            $memberstats |
                Select-Object -ExpandProperty 'serverside.curConns' |
                Should Not Be Null
            $memberstats |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be 1
        }
        It "Gets pool member statistics by Name[]" -TestCases $PoolMemberTestCases {
            param($PoolName,$Name)
            $memberstats = Get-Pool -PoolName $PoolName |
                Get-PoolMemberStats -Name $Name
            $memberstats |
                Select-Object -ExpandProperty 'serverside.curConns' |
                Should Not Be Null
            $memberstats |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be 1
        }
    }
}
Describe "PoolMonitor" {
    Context "Get" {
        It "Gets pool monitors *" {
            Get-PoolMonitor |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Not Be 0
        }
        It "Gets pool monitors in partition '<name>'" -TestCases $PartitionTestCases {
            param($Partition)
            
            # Pool monitors can be from a different partition than the pool.  Check GetPoolName() partition matches instead.
            $monitors = Get-PoolMonitor -Partition $Partition
            $monitors |
                Measure-Object -Sum Count | 
                Select-Object -ExpandProperty Sum | 
                Should Not Be 0
            $monitors |
                Select-Object -ExpandProperty name | 
                Should Match '/[^/]*/.*'
        }
        It "Gets pool monitors in partition '<partition>' and pool '<poolname>'" -TestCases $PoolMonitorTestCases {
            param($PoolName,$Partition)

            $monitors = Get-PoolMonitor -PoolName $PoolName -Partition $Partition
            $monitors |
                Measure-Object -Sum Count | 
                Select-Object -ExpandProperty Sum | 
                Should Not Be 0
            $monitors |
                Select-Object -ExpandProperty name | 
                Should Match '/[^/]*/.*'
        }
        It "Gets pool monitors in pool '<fullPath>'" -TestCases $PoolMonitorTestCases {
            param($fullPath)
            
            $monitors = Get-PoolMonitor -PoolName $fullPath
            $monitors |
                Measure-Object -Sum Count | 
                Select-Object -ExpandProperty Sum | 
                Should Not Be 0
            $monitors |
                Select-Object -ExpandProperty name | 
                Should Match '/[^/]*/.*'
        }
        It "Gets pool monitors by Name[]" {
            $monitors = Get-Pool -PoolName (($session.Partitions.Pools | Where-Object { -not $_.addremove }).fullPath) |
                Get-PoolMonitor -Name (($session.Partitions.PoolMonitors | Where-Object { -not $_.addremove }).fullPath)
            $monitors |
                Measure-Object -Sum Count | 
                Select-Object -ExpandProperty Sum | 
                Should Not Be 0
            $monitors |
                Select-Object -ExpandProperty name | 
                Should Match '/[^/]*/.*'
        }
    }
}
Describe "VirtualServer" {
    Context "Get" {
        It "Gets virtual servers *" {
            $virtualservers = Get-VirtualServer
            $virtualservers |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Not Be 0
        }
        It "Gets virtual servers in partition '<name>'" -TestCases $PartitionTestCases {
            param($Name)
            
            Get-VirtualServer -Partition $Name |
                Select-Object -ExpandProperty partition | 
                Should Be $Name
        }
        It "Gets virtual servers in partition '<partition>' by Name '<name>'" -TestCases $VirtualServerTestCases {
            param($Name,$Partition)
            
            Get-VirtualServer -Name $Name -Partition $Partition |
                Select-Object -ExpandProperty name | 
                Should Be $Name
        }
        It "Gets virtual servers by fullPath '<fullPath>'" -TestCases $VirtualServerTestCases {
            param($fullPath)
            
            Get-VirtualServer -Name $fullPath |
                Select-Object -ExpandProperty fullPath | 
                Should Be $fullPath
        }
        It "Gets virtual servers by Name[]" {
            Get-VirtualServer -Name (($session.Partitions.VirtualServers | Where-Object { -not $_.addremove }).fullPath) |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.VirtualServers | Where-Object { -not $_.addremove })Count
        }
        It "Gets virtual servers by Name ValueFromPipeline" {
            ($session.Partitions.VirtualServers | Where-Object { -not $_.addremove }).fullPath | 
                Get-VirtualServer |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.VirtualServers | Where-Object { -not $_.addremove }).Count
        }
        It "Gets virtual servers by Name,Partition ValueFromPipelineByPropertyName" {
            $session.Partitions.VirtualServers | Where-Object { -not $_.addremove } |
                Get-VirtualServer |
                Measure-Object | 
                Select-Object -ExpandProperty Count | 
                Should Be ($session.Partitions.VirtualServers | Where-Object { -not $_.addremove }).Count
        }
    }
}
}