$scriptroot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module (Join-Path $scriptroot 'F5-LTM\F5-LTM.psm1') -Force

Describe 'Get-HealthMonitor' -Tags 'Unit' {
    InModuleScope F5-LTM {
        Context "Strict mode PS$($PSVersionTable.PSVersion.Major)" {
            Set-StrictMode -Version latest

#region Arrange: Initialize Mocks

            # We aren't testing Get-HealthMonitorType here, just Get-HealthMonitor
            # Using a mock to return a static set of types for use by subsequent requests
            $healthmonitortypes = @('http','https','icmp','smtp','tcp')
            Mock Get-HealthMonitorType { $healthmonitortypes }

            # Mocking Invoke-RestMethodOverride for unit testing Module without F5 device connectivity
            Mock Invoke-RestMethodOverride {
                # Behavior (not state) verification is applied to this mock.
                # Therefore, the output need only meet the bare minimum requirements to maximize code coverage of the Subject Under Test.
                [pscustomobject]@{
                    kind="tm:ltm:monitor:http:httpstate"
                    items=@('bogus item for testing')
                    name='name'
                    partition='partition'
                    fullPath='/partition/name'
                    selfLink="https://localhost/mgmt/tm/ltm/monitor/type/~partition~name?ver=12.1.2"
                }
            }
            # Mock session with fictional IP,credentials, and version
            $mocksession = [pscustomobject]@{
                Name = '192.168.1.1'
                BaseURL = 'https://192.168.1.1/mgmt/tm/ltm/'
                Credential = New-Object System.Management.Automation.PSCredential ('georgejetson', (ConvertTo-SecureString 'judyr0ck$!' -AsPlainText -Force))
                LTMVersion = [Version]'11.5.1'
                WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
            } | Add-Member -Name GetLink -MemberType ScriptMethod {
                    param($Link)
                    $Link -replace 'localhost', $this.Name    
            } -PassThru

#endregion Arrange: Initialize Mocks

            It "Requests health monitors *" {
                Get-HealthMonitor -F5Session $mocksession |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'PoshLTM.HealthMonitor' }
                Assert-MockCalled Get-HealthMonitorType -Times 1 -Exactly -Scope It
                Assert-MockCalled Invoke-RestMethodOverride -Times $healthmonitortypes.Count -Exactly -Scope It
            }
            It "Requests health monitors of type '<type>'" -TestCases @(@{type='http'},@{type='https'}) {
                param($type)
                Get-HealthMonitor -F5Session $mocksession -Type $type |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'PoshLTM.HealthMonitor' }
                    Assert-MockCalled Get-HealthMonitorType -Times 0 -Scope It
                    Assert-MockCalled Invoke-RestMethodOverride -Times 1 -Exactly -Scope It
            }
            It "Requests health monitors in partition '<partition>'" -TestCases @(@{partition='Development'},@{partition='Common'}) {
                param($partition)
                Get-HealthMonitor -F5Session $mocksession -Partition $partition |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'PoshLTM.HealthMonitor' }
                Assert-MockCalled Get-HealthMonitorType -Times 1 -Exactly -Scope It
                Assert-MockCalled Invoke-RestMethodOverride -Times $healthmonitortypes.Count -Exactly -Scope It
            }
            It "Requests health monitors in partition '<partition>' by Name '<name>'" -TestCases @(@{partition='Common';name='http'},@{partition='Development';name='Test'}) {
                param($partition, $name)
                Get-HealthMonitor -F5Session $mocksession -Partition $partition -Name $name |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'PoshLTM.HealthMonitor' }
                Assert-MockCalled Get-HealthMonitorType -Times 1 -Exactly -Scope It
                Assert-MockCalled Invoke-RestMethodOverride -Times $healthmonitortypes.Count -Exactly -Scope It
            }
            It "Requests health monitors by fullPath '<fullPath>'" -TestCases @(@{fullpath='/Common/https'}) {
                param($fullpath)
                Get-HealthMonitor -F5Session $mocksession -Name $fullPath |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'PoshLTM.HealthMonitor' }
                Assert-MockCalled Get-HealthMonitorType -Times 1 -Exactly -Scope It
                Assert-MockCalled Invoke-RestMethodOverride -Times $healthmonitortypes.Count -Exactly -Scope It
            }
            It "Requests health monitors by Name[]" -TestCases @(@{name=@('http','https','tcp')}) {
                param($name)
                Get-HealthMonitor -F5Session $mocksession -Name $name |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'PoshLTM.HealthMonitor' }
                Assert-MockCalled Get-HealthMonitorType -Times 1 -Exactly -Scope It
                Assert-MockCalled Invoke-RestMethodOverride -Times ($name.Count * $healthmonitortypes.Count) -Exactly -Scope It
            }
            It "Requests health monitors by Name From Pipeline" -TestCases @(@{name=@('http','https')}) {
                param($name)
                $name | Get-HealthMonitor -F5Session $mocksession |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'PoshLTM.HealthMonitor' }
                Assert-MockCalled Get-HealthMonitorType -Times 1 -Exactly -Scope It
                Assert-MockCalled Invoke-RestMethodOverride -Times ($name.Count * $healthmonitortypes.Count) -Exactly -Scope It
            }
            It "Requests health monitors by Name and Partition From Pipeline" -TestCases @(@{ object = ([pscustomobject]@{name = 'http'; partition = 'Common'}),([pscustomobject]@{name = 'host_ashx'; partition = 'Common'}) }) {
                param($object)
                $object | Get-HealthMonitor -F5Session $mocksession |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'PoshLTM.HealthMonitor' }
                Assert-MockCalled Get-HealthMonitorType -Times 1 -Exactly -Scope It
                Assert-MockCalled Invoke-RestMethodOverride -Times ($object.Count * $healthmonitortypes.Count) -Exactly -Scope It
            }
        }
    }
}