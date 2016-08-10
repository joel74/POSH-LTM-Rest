$scriptroot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Import-Module (Join-Path $scriptroot 'F5-LTM\F5-LTM.psm1') -Force

if (Test-Path -Path (Join-Path $HOME F5-LTM.json)) {
    . (Join-Path $HOME F5-LTM.TestCases.ps1)
}
Describe 'HealthMonitor' {
    Context 'Get' {
        If ($Sessions) {
            If ($Get_HealthMonitor) {
                It "Gets health monitors * on '<session>'" -TestCases $Get_HealthMonitor {
                    param($session)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-HealthMonitor -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Not Be 0
                }
            }
            If ($Get_HealthMonitor_ByType) {
                It "Gets health monitors of type '<type>' on '<session>'" -TestCases $Get_HealthMonitor_ByType {
                    param($session, $type)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-HealthMonitor -F5Session $Sessions[$session] -Type $type |
                        Select-Object -ExpandProperty type | 
                        Should Be $type
                }
            }
            If ($Get_HealthMonitor_ByPartition) {
                It "Gets health monitors in partition '<partition>' on '<session>'" -TestCases $Get_HealthMonitor_ByPartition {
                    param($session, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-HealthMonitor -F5Session $Sessions[$session] -Partition $partition |
                        Select-Object -ExpandProperty partition | 
                        Should Be $partition
                }
            }            
            If ($Get_HealthMonitor_ByNameAndPartition) {
                It "Gets health monitors in partition '<partition>' by Name '<name>' on '<session>'" -TestCases $Get_HealthMonitor_ByNameAndPartition {
                    param($session, $partition, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-HealthMonitor -F5Session $Sessions[$session] -Partition $partition -Name $name |
                        Select-Object -ExpandProperty name | 
                        Should Be $Name
                }
            }
            If ($Get_HealthMonitor_ByFullpath) {
                It "Gets health monitors by fullPath '<fullPath>' on '<session>'" -TestCases $Get_HealthMonitor_ByFullpath {
                    param($session, $partition, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-HealthMonitor -F5Session $Sessions[$session] -Name $fullPath |
                        Select-Object -ExpandProperty fullPath | 
                        Should Be $fullPath
                }
            }
            If ($Get_HealthMonitor_ByNameArray) {
                It "Gets health monitors by Name[] on '<session>'" -TestCases $Get_HealthMonitor_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-HealthMonitor -F5Session $Sessions[$session] -Name $name |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
            If ($Get_HealthMonitor_ByNameFromPipeline) {
                It "Gets health monitors by Name From Pipeline on '<session>'" -TestCases $Get_HealthMonitor_ByNameFromPipeline {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $name | Get-HealthMonitor -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
            If ($Get_HealthMonitor_ByNameAndPartitionFromPipeline) {
                It "Gets health monitors by Name and Partition From Pipeline on '<session>'" -TestCases $Get_HealthMonitor_ByNameAndPartitionFromPipeline {
                    param($session, $object)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $object | Get-HealthMonitor -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $object.Count
                }
            }
        }
    }
}
Describe 'HealthMonitorType' {
    Context 'Get' {
        If ($Sessions) {
            If ($Get_HealthMonitorType) {
                It "Gets health monitor types * on '<session>'" -TestCases $Get_HealthMonitorType {
                    param($session)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-HealthMonitorType -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Not Be 0
                }
            }
            If ($Get_HealthMonitorType_ByName) {
                It "Gets health monitor types by Name '<name>' on '<session>'" -TestCases $Get_HealthMonitorType_ByName {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-HealthMonitorType -F5Session $Sessions[$session] -Name $name |
                        Should Be $name
                }
            }
            If ($Get_HealthMonitorType_ByNameArray) {
                It "Gets health monitor types by Name[] on '<session>'" -TestCases $Get_HealthMonitorType_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-HealthMonitorType -F5Session $Sessions[$session] -Name $name |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
            If ($Get_HealthMonitorType_ByNameFromPipeline) {
                It "Gets health monitor types by Name From Pipeline on '<session>'" -TestCases $Get_HealthMonitorType_ByNameFromPipeline {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $name | Get-HealthMonitorType -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
        }
    }
}
Describe 'iRule' {
    Context 'Get' {
        If ($Sessions) {
            If ($Get_iRule) {
                It "Gets irules* on '<session>'" -TestCases $Get_iRule {
                    param($session)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-iRule -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Not Be 0
                }
            }
            If ($Get_iRule_ByName) {
                It "Gets irules by Name '<name>' on '<session>'" -TestCases $Get_iRule_ByName {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-iRule -F5Session $Sessions[$session] -Name $name |
                        Select-Object -ExpandProperty name | 
                        Should Be $name
                }
            }
             If ($Get_iRule_ByPartition) {
                It "Gets irules in partition '<partition>' on '<session>'" -TestCases $Get_iRule_ByPartition {
                    param($session, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-iRule -F5Session $Sessions[$session] -Partition $partition |
                        Select-Object -ExpandProperty partition | 
                        Should Be $partition
                }
            }            
            If ($Get_iRule_ByNameAndPartition) {
                It "Gets irules in partition '<partition>' by Name '<name>' on '<session>'" -TestCases $Get_iRule_ByNameAndPartition {
                    param($session, $partition, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-iRule -F5Session $Sessions[$session] -Partition $partition -Name $name |
                        Select-Object -ExpandProperty name | 
                        Should Be $Name
                }
            }
            If ($Get_iRule_ByFullpath) {
                It "Gets irules by fullPath '<fullPath>' on '<session>'" -TestCases $Get_iRule_ByFullpath {
                    param($session, $partition, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-iRule -F5Session $Sessions[$session] -Name $fullPath |
                        Select-Object -ExpandProperty fullPath | 
                        Should Be $fullPath
                }
            }
           If ($Get_iRule_ByNameArray) {
                It "Gets irules by Name[] on '<session>'" -TestCases $Get_iRule_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-iRule -F5Session $Sessions[$session] -Name $name |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
            If ($Get_iRule_ByNameFromPipeline) {
                It "Gets irules by Name From Pipeline on '<session>'" -TestCases $Get_iRule_ByNameFromPipeline {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $name | Get-iRule -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
             If ($Get_iRule_ByNameAndPartitionFromPipeline) {
                It "Gets irules by Name and Partition From Pipeline on '<session>'" -TestCases $Get_iRule_ByNameAndPartitionFromPipeline {
                    param($session, $object)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $object | Get-iRule -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $object.Count
                }
            }
       }
    }
}
Describe 'Node' {
    Context 'Get' {
        If ($Sessions) {
            If ($Get_Node) {
                It "Gets nodes * on '<session>'" -TestCases $Get_Node {
                    param($session)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-Node -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Not Be 0
                }
            }
             If ($Get_Node_ByPartition) {
                It "Gets nodes in partition '<partition>' on '<session>'" -TestCases $Get_Node_ByPartition {
                    param($session, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-Node -F5Session $Sessions[$session] -Partition $partition |
                        Select-Object -ExpandProperty partition | 
                        Should Be $partition
                }
            }            
            If ($Get_Node_ByNameAndPartition) {
                It "Gets nodes in partition '<partition>' by Name '<name>' on '<session>'" -TestCases $Get_Node_ByNameAndPartition {
                    param($session, $partition, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-Node -F5Session $Sessions[$session] -Partition $partition -Name $name |
                        Select-Object -ExpandProperty name | 
                        Should Be $Name
                }
            }
            If ($Get_Node_ByFullpath) {
                It "Gets nodes by fullPath '<fullPath>' on '<session>'" -TestCases $Get_Node_ByFullpath {
                    param($session, $partition, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-Node -F5Session $Sessions[$session] -Name $fullPath |
                        Select-Object -ExpandProperty fullPath | 
                        Should Be $fullPath
                }
            }
           If ($Get_Node_ByNameArray) {
                It "Gets nodes by Name[] on '<session>'" -TestCases $Get_Node_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-Node -F5Session $Sessions[$session] -Name $name |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
            If ($Get_Node_ByNameFromPipeline) {
                It "Gets nodes by Name From Pipeline on '<session>'" -TestCases $Get_Node_ByNameFromPipeline {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $name | Get-Node -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
             If ($Get_Node_ByNameAndPartitionFromPipeline) {
                It "Gets nodes by Name and Partition From Pipeline on '<session>'" -TestCases $Get_Node_ByNameAndPartitionFromPipeline {
                    param($session, $object)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $object | Get-Node -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $object.Count
                }
            }
       }
    }
}
Describe 'Partition' {
    Context 'Get' {
        If ($Sessions) {
            If ($Get_Partition) {
                It "Gets partitions * on '<session>'" -TestCases $Get_Partition {
                    param($session)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-Partition -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Not Be 0
                }
            }
            If ($Get_Partition_ByName) {
                It "Gets partitions by Name '<name>' on '<session>'" -TestCases $Get_Partition_ByName {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-Partition -F5Session $Sessions[$session] -Name $name |
                        Should Be $name
                }
            }
            If ($Get_Partition_ByNameArray) {
                It "Gets partitions by Name[] on '<session>'" -TestCases $Get_Partition_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-Partition -F5Session $Sessions[$session] -Name $name |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
            If ($Get_Partition_ByNameFromPipeline) {
                It "Gets partitions by Name From Pipeline on '<session>'" -TestCases $Get_Partition_ByNameFromPipeline {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $name | Get-Partition -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
        }
    }
}
Describe 'Pool' {
    Context 'Get' {
        If ($Sessions) {
            If ($Get_Pool) {
                It "Gets pools * on '<session>'" -TestCases $Get_Pool {
                    param($session)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-Pool -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Not Be 0
                }
            }
             If ($Get_Pool_ByPartition) {
                It "Gets pools in partition '<partition>' on '<session>'" -TestCases $Get_Pool_ByPartition {
                    param($session, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-Pool -F5Session $Sessions[$session] -Partition $partition |
                        Select-Object -ExpandProperty partition | 
                        Should Be $partition
                }
            }            
            If ($Get_Pool_ByNameAndPartition) {
                It "Gets pools in partition '<partition>' by Name '<name>' on '<session>'" -TestCases $Get_Pool_ByNameAndPartition {
                    param($session, $partition, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-Pool -F5Session $Sessions[$session] -Partition $partition -Name $name |
                        Select-Object -ExpandProperty name | 
                        Should Be $Name
                }
            }
            If ($Get_Pool_ByFullpath) {
                It "Gets pools by fullPath '<fullPath>' on '<session>'" -TestCases $Get_Pool_ByFullpath {
                    param($session, $partition, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-Pool -F5Session $Sessions[$session] -Name $fullPath |
                        Select-Object -ExpandProperty fullPath | 
                        Should Be $fullPath
                }
            }
           If ($Get_Pool_ByNameArray) {
                It "Gets pools by Name[] on '<session>'" -TestCases $Get_Pool_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-Pool -F5Session $Sessions[$session] -Name $name |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
            If ($Get_Pool_ByNameFromPipeline) {
                It "Gets pools by Name From Pipeline on '<session>'" -TestCases $Get_Pool_ByNameFromPipeline {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $name | Get-Pool -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
             If ($Get_Pool_ByNameAndPartitionFromPipeline) {
                It "Gets pools by Name and Partition From Pipeline on '<session>'" -TestCases $Get_Pool_ByNameAndPartitionFromPipeline {
                    param($session, $object)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $object | Get-Pool -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $object.Count
                }
            }
       }
    }
}
Describe "PoolMember" {
    Context "Get" {
        if ($Sessions) {
            if ($Get_PoolMember) {
                It "Gets pool members * on '<session>'" -TestCases $Get_PoolMember {
                    param($session)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-PoolMember -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Not Be 0
                }
            }
             If ($Get_PoolMember_ByPartition) {
                It "Gets pool members in partition '<partition> on '<session>'" -TestCases $Get_PoolMember_ByPartition {
                    param($session, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-PoolMember -F5Session $Sessions[$session] -Partition $partition |
                        ForEach-Object { [Regex]::Match($_.GetPoolName(),'(?<=^/)[^/]*').Value } |
                        Should Be $partition
                }
            }
            If ($Get_PoolMember_ByPoolnameAndPartition) {
                It "Gets pool members in partition '<partition>' and pool '<poolname>' on '<session>'" -TestCases $Get_PoolMember_ByPoolnameAndPartition {
                    param($session, $partition, $poolname)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    # Pool members can be from a different partition than the pool.  Check GetPoolName() partition matches instead.
                    Get-PoolMember -F5Session $Sessions[$session] -PoolName $poolname -Partition $Partition |
                        ForEach-Object { [Regex]::Match($_.GetPoolName(),'(?<=^/)[^/]*').Value } |
                        Should Be $partition
                }
            }
            If ($Get_PoolMember_ByPoolnameFullpath) {
                It "Gets pool members in pool by Fullpath '<fullpath>' on '<session>'" -TestCases $Get_PoolMember_ByPoolnameFullpath {
                    param($session, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-PoolMember -F5Session $Sessions[$session] -PoolName $fullPath |
                        ForEach-Object { $_.GetPoolName() } |
                        Should Be $fullPath
                }
            }
            If ($Get_PoolMember_ByAddressArray) {
                It "Gets pool members in pool '<poolname>' by Address[] on '<session>'" -TestCases $Get_PoolMember_ByAddressArray {
                    param($session, $address, $poolname)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-Pool -F5Session $Sessions[$session] -PoolName $poolname |
                        Get-PoolMember -F5Session $Sessions[$session] -Address $address |
                        Select-Object -ExpandProperty Address | 
                        Should Match '^\d+\.\d+\.\d+\.\d+'
                }
            }
            If ($Get_PoolMember_ByNameArray) {
                It "Gets pool members in pool '<poolname>' by Name[] on '<session>'" -TestCases $Get_PoolMember_ByNameArray {
                    param($session, $name, $poolname)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-Pool -F5Session $Sessions[$session] -PoolName $poolname |
                        Get-PoolMember -F5Session $Sessions[$session] -Name $name |
                        Select-Object -ExpandProperty Name | 
                        Should Match '^.+:\d+'
                }
            }
        }
    }
}
Describe "PoolMemberStats" {
    Context "Get" {
        if ($Sessions) {
            if ($Get_PoolMemberStats) {
                It "Gets pool member statistics in partition '<partition>' and pool '<poolname>' on '<session>'" -TestCases $Get_PoolMemberStats {
                    param($session, $poolname, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-PoolMemberStats -F5Session $Sessions[$session] -PoolName $poolname -Partition $partition |
                        Select-Object -ExpandProperty 'serverside.curConns' |
                        Should Not Be Null
                }
            }
            if ($Get_PoolMemberStats_ByPoolnameFullpath) {
                It "Gets pool member statistics in pool '<fullpath>' on '<session>'" -TestCases $Get_PoolMemberStats_ByPoolnameFullpath {
                    param($session, $fullPath)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-PoolMemberStats -F5Session $Sessions[$session] -PoolName $fullPath |
                        Select-Object -ExpandProperty 'serverside.curConns' |
                        Should Not Be Null
                }
            }
            if ($Get_PoolMemberStats_ByAddressArray) {
                It "Gets pool member statistics in pool '<fullpath>' and Address[] on '<session>'" -TestCases $Get_PoolMemberStats_ByAddressArray {
                    param($session, $address, $poolname)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $memberstats = Get-Pool -F5Session $Sessions[$session] -PoolName $poolname |
                        Get-PoolMemberStats -F5Session $Sessions[$session] -Address $address
                    $memberstats |
                        Select-Object -ExpandProperty 'serverside.curConns' |
                        Should Not Be Null
                    $memberstats |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $address.Count
                }
            }
            if ($Get_PoolMemberStatsByNameArray) {
                It "Gets pool member statistics in pool '<poolname>' and Name[] on '<session>'" -TestCases $Get_PoolMemberStatsByNameArray {
                    param($session, $name, $poolname)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $memberstats = Get-Pool -F5Session $Sessions[$session] -PoolName $poolname |
                        Get-PoolMemberStats -F5Session $Sessions[$session] -name $name
                    $memberstats |
                        Select-Object -ExpandProperty 'serverside.curConns' |
                        Should Not Be Null
                    $memberstats |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
        }
    }
}
Describe "PoolMonitor" {
    Context "Get" {
        if ($Sessions) {
            if ($Get_PoolMonitor) {
                It "Gets pool monitors * on '<session>'" -TestCases $Get_PoolMonitor {
                    param($session)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-PoolMonitor -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Not Be 0
                }
            }
             If ($Get_PoolMonitor_ByPartition) {
                It "Gets pool monitors in partition '<partition> on '<session>'" -TestCases $Get_PoolMonitor_ByPartition {
                    param($session, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $monitors = Get-PoolMonitor -F5Session $Sessions[$session] -Partition $partition
                    $monitors |
                        Measure-Object -Sum Count | 
                        Select-Object -ExpandProperty Sum | 
                        Should Not Be 0
                    $monitors |
                        Select-Object -ExpandProperty name | 
                        Should Match '/[^/]*/.*'
                }
            }
            If ($Get_PoolMonitor_ByPoolnameAndPartition) {
                It "Gets pool monitors in partition '<partition>' and pool '<poolname>' on '<session>'" -TestCases $Get_PoolMonitor_ByPoolnameAndPartition {
                    param($session, $partition, $poolname)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $monitors = Get-PoolMonitor -F5Session $Sessions[$session] -PoolName $poolname -Partition $partition
                    $monitors |
                        Measure-Object -Sum Count | 
                        Select-Object -ExpandProperty Sum | 
                        Should Not Be 0
                    $monitors |
                        Select-Object -ExpandProperty name | 
                        Should Match '/[^/]*/.*'
                }
            }
            If ($Get_PoolMonitor_ByPoolnameFullpath) {
                It "Gets pool monitors in pool by Fullpath '<fullpath>' on '<session>'" -TestCases $Get_PoolMonitor_ByPoolnameFullpath {
                    param($session, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $monitors = Get-PoolMonitor -F5Session $Sessions[$session] -PoolName $fullpath
                    $monitors |
                        Measure-Object -Sum Count | 
                        Select-Object -ExpandProperty Sum | 
                        Should Not Be 0
                    $monitors |
                        Select-Object -ExpandProperty name | 
                        Should Match '/[^/]*/.*'
                }
            }
            If ($Get_PoolMonitor_ByFullpathArray) {
                It "Gets pool monitors in pool by Fullpath[] on '<session>'" -TestCases $Get_PoolMonitor_ByFullpathArray {
                    param($session, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $monitors = Get-PoolMonitor -F5Session $Sessions[$session] -PoolName $fullpath
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
    }
}
Describe 'VirtualServer' {
    Context 'Get' {
        If ($Sessions) {
            If ($Get_VirtualServer) {
                It "Gets virtual servers * on '<session>'" -TestCases $Get_VirtualServer {
                    param($session)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-VirtualServer -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Not Be 0
                }
            }
             If ($Get_VirtualServer_ByPartition) {
                It "Gets virtual servers in partition '<partition>' on '<session>'" -TestCases $Get_VirtualServer_ByPartition {
                    param($session, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-VirtualServer -F5Session $Sessions[$session] -Partition $partition |
                        Select-Object -ExpandProperty partition | 
                        Should Be $partition
                }
            }            
            If ($Get_VirtualServer_ByNameAndPartition) {
                It "Gets virtual servers in partition '<partition>' by Name '<name>' on '<session>'" -TestCases $Get_VirtualServer_ByNameAndPartition {
                    param($session, $partition, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-VirtualServer -F5Session $Sessions[$session] -Partition $partition -Name $name |
                        Select-Object -ExpandProperty name | 
                        Should Be $Name
                }
            }
            If ($Get_VirtualServer_ByFullpath) {
                It "Gets virtual servers by fullPath '<fullPath>' on '<session>'" -TestCases $Get_VirtualServer_ByFullpath {
                    param($session, $partition, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-VirtualServer -F5Session $Sessions[$session] -Name $fullPath |
                        Select-Object -ExpandProperty fullPath | 
                        Should Be $fullPath
                }
            }
           If ($Get_VirtualServer_ByNameArray) {
                It "Gets virtual servers by Name[] on '<session>'" -TestCases $Get_VirtualServer_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    Get-VirtualServer -F5Session $Sessions[$session] -Name $name |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
            If ($Get_VirtualServer_ByNameFromPipeline) {
                It "Gets virtual servers by Name From Pipeline on '<session>'" -TestCases $Get_VirtualServer_ByNameFromPipeline {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $name | Get-VirtualServer -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $name.Count
                }
            }
             If ($Get_VirtualServer_ByNameAndPartitionFromPipeline) {
                It "Gets virtual servers by Name and Partition From Pipeline on '<session>'" -TestCases $Get_VirtualServer_ByNameAndPartitionFromPipeline {
                    param($session, $object)
                    $Sessions.ContainsKey($session) | Should Be $true
                    
                    $object | Get-VirtualServer -F5Session $Sessions[$session] |
                        Measure-Object | 
                        Select-Object -ExpandProperty Count | 
                        Should Be $object.Count
                }
            }
       }
    }
}