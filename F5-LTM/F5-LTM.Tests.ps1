$scriptroot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Import-Module (Join-Path $scriptroot 'F5-LTM\F5-LTM.psm1') -Force

$PSVersion = $PSVersionTable.PSVersion.Major

$F5LTMTestCases = @{}
[Regex]::Matches((Get-Content $MyInvocation.MyCommand.Path -raw),'(?<=F5LTMTestCases\.)Get_\w*') |
    Select-Object -ExpandProperty Value -Unique |
    Sort-Object | % {
        $F5LTMTestCases.Add($_, @())
}
$TestCasePath = Invoke-NullCoalescing { $env:F5LTMTestCases } { (Join-Path $HOME F5-LTM.TestCases.ps1) }
if (Test-Path -Path $TestCasePath) {
    . $TestCasePath
} else {
    Write-Host ('Writing test case template to {0}' -f $TestCasePath) -ForegroundColor Green
    $F5LTMTestCasesTemplate = @"
`$credentials = New-Object System.Management.Automation.PSCredential ('[username]', (ConvertTo-SecureString '[password]' -AsPlainText -Force))

`$Sessions = @{}
`$Sessions.Add('default', (New-F5Session -LTMName '[ipaddress]' -LTMCredentials `$credentials -Default -PassThrough))

"@
    $F5LTMTestCases.Keys | Sort-Object | ForEach-Object {
        $params = [Regex]::Match($_, '(?<=_By).*$') -replace 'PoolnameFullpath','fullpath' -split 'And'
        $hashvalues = @()
        if ($_ -match 'FromPipeline$') {
            for($x=0;$x -le 1; $x++) {
                $pipelineobjects = @()
                $pipelineparams = @()
                foreach($p in $params) {
                    if ($p) {
                        $pipelineparams += ' {0} = ''[{0}]'' ' -f ($p.ToLower() -replace 'frompipeline','')
                    }
                }
                $pipelineobjects += ('([pscustomobject]@{{{0}}})' -f ($pipelineparams -join ';'))
            }
            $hashvalues += '; object = {0}' -f ($pipelineobjects -join ',')
        } else {
            foreach($p in $params) {
                if ($p) {
                    if ($p -match 'Array$') {
                        $hashvalues += '; {0} = ''[{0}1]'',''[{0}2]'',''[{0}3]''' -f ($p.ToLower() -replace 'array','')
                    } else {
                        $hashvalues += '; {0} = ''[{0}]''' -f $p.ToLower()
                    }
                }
            }
        }
        $F5LTMTestCasesTemplate += '$F5LTMTestCases.{0} += @{{ session = ''default''{1} }}{2}' -f $_,($hashvalues -join ''),[Environment]::NewLine
    }
    $F5LTMTestCasesTemplate | Out-File -FilePath $TestCasePath
}
$SessionsTestCases = @()
foreach ($key in $Sessions.Keys) {
    $SessionsTestCases += @{session=$key}
}
Describe 'TestCases' -Tags 'Validation' {
    Context "Strict mode PS$PSVersion" {
        Set-StrictMode -Version latest
        $F5LTMTestCases.Keys | Sort-Object | ForEach-Object {
            If ($F5LTMTestCases[$_].Count -eq 0) {
                Write-Warning ('$F5LTMTestCases.{0} is empty' -f $_)
            }
        }
        Write-Host 'Invoke-Pester -ExcludeTag Validation to suppress empty test case warnings' -ForegroundColor Green
    }
}
Describe 'Get-HealthMonitor' {
    Context "Strict mode PS$PSVersion" {
        Set-StrictMode -Version latest
        If ($Sessions) {
            It "Gets health monitors * on '<session>'" -TestCases $SessionsTestCases {
                param($session)
                $Sessions.ContainsKey($session) | Should Be $true

                Get-HealthMonitor -F5Session $Sessions[$session] |
                    Measure-Object |
                    Select-Object -ExpandProperty Count |
                    Should Not Be 0
            }
            If ($F5LTMTestCases.Get_HealthMonitor_ByType) {
                It "Gets health monitors of type '<type>' on '<session>'" -TestCases $F5LTMTestCases.Get_HealthMonitor_ByType {
                    param($session, $type)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-HealthMonitor -F5Session $Sessions[$session] -Type $type |
                        Select-Object -ExpandProperty type |
                        Should Be $type
                }
            }
            If ($F5LTMTestCases.Get_HealthMonitor_ByPartition) {
                It "Gets health monitors in partition '<partition>' on '<session>'" -TestCases $F5LTMTestCases.Get_HealthMonitor_ByPartition {
                    param($session, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-HealthMonitor -F5Session $Sessions[$session] -Partition $partition |
                        Select-Object -ExpandProperty partition |
                        Should Be $partition
                }
            }
            If ($F5LTMTestCases.Get_HealthMonitor_ByNameAndPartition) {
                It "Gets health monitors in partition '<partition>' by Name '<name>' on '<session>'" -TestCases $F5LTMTestCases.Get_HealthMonitor_ByNameAndPartition {
                    param($session, $partition, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-HealthMonitor -F5Session $Sessions[$session] -Partition $partition -Name $name |
                        Select-Object -ExpandProperty name |
                        Should Be $Name
                }
            }
            If ($F5LTMTestCases.Get_HealthMonitor_ByFullpath) {
                It "Gets health monitors by fullPath '<fullPath>' on '<session>'" -TestCases $F5LTMTestCases.Get_HealthMonitor_ByFullpath {
                    param($session, $partition, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-HealthMonitor -F5Session $Sessions[$session] -Name $fullPath |
                        Select-Object -ExpandProperty fullPath |
                        Should Be $fullPath
                }
            }
            If ($F5LTMTestCases.Get_HealthMonitor_ByNameArray) {
                It "Gets health monitors by Name[] on '<session>'" -TestCases $F5LTMTestCases.Get_HealthMonitor_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-HealthMonitor -F5Session $Sessions[$session] -Name $name |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should Be $name.Count
                }
            }
            If ($F5LTMTestCases.Get_HealthMonitor_ByNameFromPipeline) {
                It "Gets health monitors by Name From Pipeline on '<session>'" -TestCases $F5LTMTestCases.Get_HealthMonitor_ByNameFromPipeline {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    $name | Get-HealthMonitor -F5Session $Sessions[$session] |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should Be $name.Count
                }
            }
            If ($F5LTMTestCases.Get_HealthMonitor_ByNameAndPartitionFromPipeline) {
                It "Gets health monitors by Name and Partition From Pipeline on '<session>'" -TestCases $F5LTMTestCases.Get_HealthMonitor_ByNameAndPartitionFromPipeline {
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
Describe 'Get-HealthMonitorType' {
    Context "Strict mode PS$PSVersion" {
        Set-StrictMode -Version latest
        If ($Sessions) {
            It "Gets health monitor types * on '<session>'" -TestCases $SessionsTestCases {
                param($session)
                $Sessions.ContainsKey($session) | Should Be $true

                Get-HealthMonitorType -F5Session $Sessions[$session] |
                    Measure-Object |
                    Select-Object -ExpandProperty Count |
                    Should Not Be 0
            }
            If ($F5LTMTestCases.Get_HealthMonitorType_ByName) {
                It "Gets health monitor types by Name '<name>' on '<session>'" -TestCases $F5LTMTestCases.Get_HealthMonitorType_ByName {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-HealthMonitorType -F5Session $Sessions[$session] -Name $name |
                        Should Be $name
                }
            }
            If ($F5LTMTestCases.Get_HealthMonitorType_ByNameArray) {
                It "Gets health monitor types by Name[] on '<session>'" -TestCases $F5LTMTestCases.Get_HealthMonitorType_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-HealthMonitorType -F5Session $Sessions[$session] -Name $name |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should Be $name.Count
                }
            }
            If ($F5LTMTestCases.Get_HealthMonitorType_ByNameFromPipeline) {
                It "Gets health monitor types by Name From Pipeline on '<session>'" -TestCases $F5LTMTestCases.Get_HealthMonitorType_ByNameFromPipeline {
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
Describe 'Get-iRule' {
    Context "Strict mode PS$PSVersion" {
        Set-StrictMode -Version latest
        If ($Sessions) {
            It "Gets irules* on '<session>'" -TestCases $SessionsTestCases {
                param($session)
                $Sessions.ContainsKey($session) | Should Be $true

                Get-iRule -F5Session $Sessions[$session] |
                    Measure-Object |
                    Select-Object -ExpandProperty Count |
                    Should Not Be 0
            }
            If ($F5LTMTestCases.Get_iRule_ByName) {
                It "Gets irules by Name '<name>' on '<session>'" -TestCases $F5LTMTestCases.Get_iRule_ByName {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-iRule -F5Session $Sessions[$session] -Name $name |
                        Select-Object -ExpandProperty name |
                        Should Be $name
                }
            }
             If ($F5LTMTestCases.Get_iRule_ByPartition) {
                It "Gets irules in partition '<partition>' on '<session>'" -TestCases $F5LTMTestCases.Get_iRule_ByPartition {
                    param($session, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-iRule -F5Session $Sessions[$session] -Partition $partition |
                        Select-Object -ExpandProperty partition |
                        Should Be $partition
                }
            }
            If ($F5LTMTestCases.Get_iRule_ByNameAndPartition) {
                It "Gets irules in partition '<partition>' by Name '<name>' on '<session>'" -TestCases $F5LTMTestCases.Get_iRule_ByNameAndPartition {
                    param($session, $partition, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-iRule -F5Session $Sessions[$session] -Partition $partition -Name $name |
                        Select-Object -ExpandProperty name |
                        Should Be $Name
                }
            }
            If ($F5LTMTestCases.Get_iRule_ByFullpath) {
                It "Gets irules by fullPath '<fullPath>' on '<session>'" -TestCases $F5LTMTestCases.Get_iRule_ByFullpath {
                    param($session, $partition, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-iRule -F5Session $Sessions[$session] -Name $fullPath |
                        Select-Object -ExpandProperty fullPath |
                        Should Be $fullPath
                }
            }
           If ($F5LTMTestCases.Get_iRule_ByNameArray) {
                It "Gets irules by Name[] on '<session>'" -TestCases $F5LTMTestCases.Get_iRule_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-iRule -F5Session $Sessions[$session] -Name $name |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should Be $name.Count
                }
            }
            If ($F5LTMTestCases.Get_iRule_ByNameFromPipeline) {
                It "Gets irules by Name From Pipeline on '<session>'" -TestCases $F5LTMTestCases.Get_iRule_ByNameFromPipeline {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    $name | Get-iRule -F5Session $Sessions[$session] |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should Be $name.Count
                }
            }
             If ($F5LTMTestCases.Get_iRule_ByNameAndPartitionFromPipeline) {
                It "Gets irules by Name and Partition From Pipeline on '<session>'" -TestCases $F5LTMTestCases.Get_iRule_ByNameAndPartitionFromPipeline {
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
Describe 'Get-Node' {
    Context "Strict mode PS$PSVersion" {
        Set-StrictMode -Version latest
        If ($Sessions) {
            It "Gets nodes * on '<session>'" -TestCases $SessionsTestCases {
                param($session)
                $Sessions.ContainsKey($session) | Should Be $true

                Get-Node -F5Session $Sessions[$session] |
                    Measure-Object |
                    Select-Object -ExpandProperty Count |
                    Should Not Be 0
            }
             If ($F5LTMTestCases.Get_Node_ByPartition) {
                It "Gets nodes in partition '<partition>' on '<session>'" -TestCases $F5LTMTestCases.Get_Node_ByPartition {
                    param($session, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-Node -F5Session $Sessions[$session] -Partition $partition |
                        Select-Object -ExpandProperty partition |
                        Should Be $partition
                }
            }
            If ($F5LTMTestCases.Get_Node_ByNameAndPartition) {
                It "Gets nodes in partition '<partition>' by Name '<name>' on '<session>'" -TestCases $F5LTMTestCases.Get_Node_ByNameAndPartition {
                    param($session, $partition, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-Node -F5Session $Sessions[$session] -Partition $partition -Name $name |
                        Select-Object -ExpandProperty name |
                        Should Be $Name
                }
            }
            If ($F5LTMTestCases.Get_Node_ByFullpath) {
                It "Gets nodes by fullPath '<fullPath>' on '<session>'" -TestCases $F5LTMTestCases.Get_Node_ByFullpath {
                    param($session, $partition, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-Node -F5Session $Sessions[$session] -Name $fullPath |
                        Select-Object -ExpandProperty fullPath |
                        Should Be $fullPath
                }
            }
           If ($F5LTMTestCases.Get_Node_ByNameArray) {
                It "Gets nodes by Name[] on '<session>'" -TestCases $F5LTMTestCases.Get_Node_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-Node -F5Session $Sessions[$session] -Name $name |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should Be $name.Count
                }
            }
            If ($F5LTMTestCases.Get_Node_ByNameFromPipeline) {
                It "Gets nodes by Name From Pipeline on '<session>'" -TestCases $F5LTMTestCases.Get_Node_ByNameFromPipeline {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    $name | Get-Node -F5Session $Sessions[$session] |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should Be $name.Count
                }
            }
             If ($F5LTMTestCases.Get_Node_ByNameAndPartitionFromPipeline) {
                It "Gets nodes by Name and Partition From Pipeline on '<session>'" -TestCases $F5LTMTestCases.Get_Node_ByNameAndPartitionFromPipeline {
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
Describe 'Get-Partition' {
    Context "Strict mode PS$PSVersion" {
        Set-StrictMode -Version latest
        If ($Sessions) {
            It "Gets partitions * on '<session>'" -TestCases $SessionsTestCases {
                param($session)
                $Sessions.ContainsKey($session) | Should Be $true

                Get-BIGIPPartition -F5Session $Sessions[$session] |
                    Measure-Object |
                    Select-Object -ExpandProperty Count |
                    Should Not Be 0
            }
            If ($F5LTMTestCases.Get_BIGIPPartition_ByName) {
                It "Gets partitions by Name '<name>' on '<session>'" -TestCases $F5LTMTestCases.Get_BIGIPPartition_ByName {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-BIGIPPartition -F5Session $Sessions[$session] -Name $name |
                        Should Be $name
                }
            }
            If ($F5LTMTestCases.Get_BIGIPPartition_ByNameArray) {
                It "Gets partitions by Name[] on '<session>'" -TestCases $F5LTMTestCases.Get_BIGIPPartition_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-BIGIPPartition -F5Session $Sessions[$session] -Name $name |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should Be $name.Count
                }
            }
            If ($F5LTMTestCases.Get_BIGIPPartition_ByNameFromPipeline) {
                It "Gets partitions by Name From Pipeline on '<session>'" -TestCases $F5LTMTestCases.Get_BIGIPPartition_ByNameFromPipeline {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    $name | Get-BIGIPPartition -F5Session $Sessions[$session] |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should Be $name.Count
                }
            }
        }
    }
}
Describe 'Get-Pool' {
    Context "Strict mode PS$PSVersion" {
        Set-StrictMode -Version latest
        If ($Sessions) {
            It "Gets pools * on '<session>'" -TestCases $SessionsTestCases {
                param($session)
                $Sessions.ContainsKey($session) | Should Be $true

                Get-Pool -F5Session $Sessions[$session] |
                    Measure-Object |
                    Select-Object -ExpandProperty Count |
                    Should Not Be 0
            }
            If ($F5LTMTestCases.Get_Pool_ByPartition) {
                It "Gets pools in partition '<partition>' on '<session>'" -TestCases $F5LTMTestCases.Get_Pool_ByPartition {
                    param($session, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-Pool -F5Session $Sessions[$session] -Partition $partition |
                        Select-Object -ExpandProperty partition |
                        Should Be $partition
                }
            }
            If ($F5LTMTestCases.Get_Pool_ByNameAndPartition) {
                It "Gets pools in partition '<partition>' by Name '<name>' on '<session>'" -TestCases $F5LTMTestCases.Get_Pool_ByNameAndPartition {
                    param($session, $partition, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-Pool -F5Session $Sessions[$session] -Partition $partition -Name $name |
                        Select-Object -ExpandProperty name |
                        Should Be $Name
                }
            }
            If ($F5LTMTestCases.Get_Pool_ByFullpath) {
                It "Gets pools by fullPath '<fullPath>' on '<session>'" -TestCases $F5LTMTestCases.Get_Pool_ByFullpath {
                    param($session, $partition, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-Pool -F5Session $Sessions[$session] -Name $fullPath |
                        Select-Object -ExpandProperty fullPath |
                        Should Be $fullPath
                }
            }
           If ($F5LTMTestCases.Get_Pool_ByNameArray) {
                It "Gets pools by Name[] on '<session>'" -TestCases $F5LTMTestCases.Get_Pool_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-Pool -F5Session $Sessions[$session] -Name $name |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should Be $name.Count
                }
            }
            If ($F5LTMTestCases.Get_Pool_ByNameFromPipeline) {
                It "Gets pools by Name From Pipeline on '<session>'" -TestCases $F5LTMTestCases.Get_Pool_ByNameFromPipeline {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    $name | Get-Pool -F5Session $Sessions[$session] |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should Be $name.Count
                }
            }
             If ($F5LTMTestCases.Get_Pool_ByNameAndPartitionFromPipeline) {
                It "Gets pools by Name and Partition From Pipeline on '<session>'" -TestCases $F5LTMTestCases.Get_Pool_ByNameAndPartitionFromPipeline {
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
Describe 'Get-PoolMember' {
    Context "Strict mode PS$PSVersion" {
        Set-StrictMode -Version latest
        if ($Sessions) {
            It "Gets pool members * on '<session>'" -TestCases $SessionsTestCases {
                param($session)
                $Sessions.ContainsKey($session) | Should Be $true

                Get-PoolMember -F5Session $Sessions[$session] |
                    Measure-Object |
                    Select-Object -ExpandProperty Count |
                    Should Not Be 0
            }
             If ($F5LTMTestCases.Get_PoolMember_ByPartition) {
                It "Gets pool members in partition '<partition>' on '<session>'" -TestCases $F5LTMTestCases.Get_PoolMember_ByPartition {
                    param($session, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-PoolMember -F5Session $Sessions[$session] -Partition $partition |
                        ForEach-Object { [Regex]::Match($_.GetPoolName(),'(?<=^/)[^/]*').Value } |
                        Should Be $partition
                }
            }
            If ($F5LTMTestCases.Get_PoolMember_ByPoolnameAndPartition) {
                It "Gets pool members in partition '<partition>' and pool '<poolname>' on '<session>'" -TestCases $F5LTMTestCases.Get_PoolMember_ByPoolnameAndPartition {
                    param($session, $partition, $poolname)
                    $Sessions.ContainsKey($session) | Should Be $true

                    # Pool members can be from a different partition than the pool.  Check GetPoolName() partition matches instead.
                    Get-PoolMember -F5Session $Sessions[$session] -PoolName $poolname -Partition $Partition |
                        ForEach-Object { [Regex]::Match($_.GetPoolName(),'(?<=^/)[^/]*').Value } |
                        Should Be $partition
                }
            }
            If ($F5LTMTestCases.Get_PoolMember_ByPoolnameFullpath) {
                It "Gets pool members in pool by Fullpath '<fullpath>' on '<session>'" -TestCases $F5LTMTestCases.Get_PoolMember_ByPoolnameFullpath {
                    param($session, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-PoolMember -F5Session $Sessions[$session] -PoolName $fullPath |
                        ForEach-Object { $_.GetPoolName() } |
                        Should Be $fullPath
                }
            }
            If ($F5LTMTestCases.Get_PoolMember_ByAddressArray) {
                It "Gets pool members in pool '<poolname>' by Address[] on '<session>'" -TestCases $F5LTMTestCases.Get_PoolMember_ByAddressArray {
                    param($session, $address, $poolname)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-Pool -F5Session $Sessions[$session] -PoolName $poolname |
                        Get-PoolMember -F5Session $Sessions[$session] -Address $address |
                        Select-Object -ExpandProperty Address |
                        Should Match '^\d+\.\d+\.\d+\.\d+'
                }
            }
            If ($F5LTMTestCases.Get_PoolMember_ByNameArray) {
                It "Gets pool members in pool '<poolname>' by Name[] on '<session>'" -TestCases $F5LTMTestCases.Get_PoolMember_ByNameArray {
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
Describe 'Get-PoolMemberStats' {
    Context "Strict mode PS$PSVersion" {
        Set-StrictMode -Version latest
        if ($Sessions) {
            if ($F5LTMTestCases.Get_PoolMemberStats) {
                It "Gets pool member statistics in partition '<partition>' and pool '<poolname>' on '<session>'" -TestCases $F5LTMTestCases.Get_PoolMemberStats {
                    param($session, $poolname, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-PoolMemberStats -F5Session $Sessions[$session] -PoolName $poolname -Partition $partition |
                        Select-Object -ExpandProperty 'serverside.curConns' |
                        Should Not Be Null
                }
            }
            if ($F5LTMTestCases.Get_PoolMemberStats_ByPoolnameFullpath) {
                It "Gets pool member statistics in pool '<fullpath>' on '<session>'" -TestCases $F5LTMTestCases.Get_PoolMemberStats_ByPoolnameFullpath {
                    param($session, $fullPath)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-PoolMemberStats -F5Session $Sessions[$session] -PoolName $fullPath |
                        Select-Object -ExpandProperty 'serverside.curConns' |
                        Should Not Be Null
                }
            }
            if ($F5LTMTestCases.Get_PoolMemberStats_ByAddressArray) {
                It "Gets pool member statistics in pool '<fullpath>' and Address[] on '<session>'" -TestCases $F5LTMTestCases.Get_PoolMemberStats_ByAddressArray {
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
            if ($F5LTMTestCases.Get_PoolMemberStats_ByNameArray) {
                It "Gets pool member statistics in pool '<poolname>' and Name[] on '<session>'" -TestCases $F5LTMTestCases.Get_PoolMemberStats_ByNameArray {
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
Describe 'Get-PoolMonitor' {
    Context "Strict mode PS$PSVersion" {
        Set-StrictMode -Version latest
        if ($Sessions) {
            It "Gets pool monitors * on '<session>'" -TestCases $SessionsTestCases {
                param($session)
                $Sessions.ContainsKey($session) | Should Be $true

                Get-PoolMonitor -F5Session $Sessions[$session] |
                    Measure-Object |
                    Select-Object -ExpandProperty Count |
                    Should Not Be 0
            }
             If ($F5LTMTestCases.Get_PoolMonitor_ByPartition) {
                It "Gets pool monitors in partition '<partition> on '<session>'" -TestCases $F5LTMTestCases.Get_PoolMonitor_ByPartition {
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
            If ($F5LTMTestCases.Get_PoolMonitor_ByPoolnameAndPartition) {
                It "Gets pool monitors in partition '<partition>' and pool '<poolname>' on '<session>'" -TestCases $F5LTMTestCases.Get_PoolMonitor_ByPoolnameAndPartition {
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
            If ($F5LTMTestCases.Get_PoolMonitor_ByPoolnameFullpath) {
                It "Gets pool monitors in pool by Fullpath '<fullpath>' on '<session>'" -TestCases $F5LTMTestCases.Get_PoolMonitor_ByPoolnameFullpath {
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
            If ($F5LTMTestCases.Get_PoolMonitor_ByFullpathArray) {
                It "Gets pool monitors in pool by Fullpath[] on '<session>'" -TestCases $F5LTMTestCases.Get_PoolMonitor_ByFullpathArray {
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
Describe 'Get-Get-VirtualServer' {
    Context "Strict mode PS$PSVersion" {
        Set-StrictMode -Version latest
        If ($Sessions) {
            It "Gets virtual servers * on '<session>'" -TestCases $SessionsTestCases {
                param($session)
                $Sessions.ContainsKey($session) | Should Be $true

                Get-VirtualServer -F5Session $Sessions[$session] |
                    Measure-Object |
                    Select-Object -ExpandProperty Count |
                    Should Not Be 0
            }
            If ($F5LTMTestCases.Get_VirtualServer_ByPartition) {
                It "Gets virtual servers in partition '<partition>' on '<session>'" -TestCases $F5LTMTestCases.Get_VirtualServer_ByPartition {
                    param($session, $partition)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-VirtualServer -F5Session $Sessions[$session] -Partition $partition |
                        Select-Object -ExpandProperty partition |
                        Should Be $partition
                }
            }
            If ($F5LTMTestCases.Get_VirtualServer_ByNameAndPartition) {
                It "Gets virtual servers in partition '<partition>' by Name '<name>' on '<session>'" -TestCases $F5LTMTestCases.Get_VirtualServer_ByNameAndPartition {
                    param($session, $partition, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-VirtualServer -F5Session $Sessions[$session] -Partition $partition -Name $name |
                        Select-Object -ExpandProperty name |
                        Should Be $Name
                }
            }
            If ($F5LTMTestCases.Get_VirtualServer_ByFullpath) {
                It "Gets virtual servers by fullPath '<fullPath>' on '<session>'" -TestCases $F5LTMTestCases.Get_VirtualServer_ByFullpath {
                    param($session, $partition, $fullpath)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-VirtualServer -F5Session $Sessions[$session] -Name $fullPath |
                        Select-Object -ExpandProperty fullPath |
                        Should Be $fullPath
                }
            }
           If ($F5LTMTestCases.Get_VirtualServer_ByNameArray) {
                It "Gets virtual servers by Name[] on '<session>'" -TestCases $F5LTMTestCases.Get_VirtualServer_ByNameArray {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    Get-VirtualServer -F5Session $Sessions[$session] -Name $name |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should Be $name.Count
                }
            }
            If ($F5LTMTestCases.Get_VirtualServer_ByNameFromPipeline) {
                It "Gets virtual servers by Name From Pipeline on '<session>'" -TestCases $F5LTMTestCases.Get_VirtualServer_ByNameFromPipeline {
                    param($session, $name)
                    $Sessions.ContainsKey($session) | Should Be $true

                    $name | Get-VirtualServer -F5Session $Sessions[$session] |
                        Measure-Object |
                        Select-Object -ExpandProperty Count |
                        Should Be $name.Count
                }
            }
             If ($F5LTMTestCases.Get_VirtualServer_ByNameAndPartitionFromPipeline) {
                It "Gets virtual servers by Name and Partition From Pipeline on '<session>'" -TestCases $F5LTMTestCases.Get_VirtualServer_ByNameAndPartitionFromPipeline {
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