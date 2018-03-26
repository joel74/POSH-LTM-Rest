# PSScriptAnalyzer - ignore creation of a SecureString using plain text for the contents of this script file
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$scriptroot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module (Join-Path $scriptroot 'F5-LTM\F5-LTM.psm1') -Force

Describe 'Get-BigIPPartition' -Tags 'Unit' {
    InModuleScope F5-LTM {
        Context "Strict mode PS$($PSVersionTable.PSVersion.Major)" {
            Set-StrictMode -Version latest

#region Arrange: Initialize Mocks

            # Mocking Invoke-RestMethodOverride for unit testing Module without F5 device connectivity
            Mock Invoke-RestMethodOverride {
                # Behavior (not state) verification is applied to this mock.
                # Therefore, the output need only meet the bare minimum requirements to maximize code coverage of the Subject Under Test.
                if ($URI -match 'JSON') {
                    # This case included to support maximum code coverage
                    [pscustomobject]@{
                        items=$null
                        name='name'
                        subPath='subPath'
                        selfLink="https://localhost/mgmt/tm/sys/folder/~name?ver=12.1.2"
                    }
                } else {
                    [pscustomobject]@{
                        items=@(@{name='bogus item for testing';subPath='subPath'})
                        name='name'
                        selfLink="https://localhost/mgmt/tm/sys/folder/~name?ver=12.1.2"
                    }
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

            It "Requests BigIP partitions *" {
                Get-BigIPPartition -F5Session $mocksession |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'string' }
                Assert-MockCalled Invoke-RestMethodOverride -Times 1 -Exactly -Scope It -ParameterFilter { $Uri.AbsoluteUri -eq ($mocksession.BaseURL -replace 'ltm/','sys/folder/?$select=name,subPath') }
            }
            # JSON test also forces a codecoverage scenario for a single item without an items property returned from the F5
            It "Requests BigIP partitions by Name '<name>'" -TestCases @(@{name='Common'},@{name='Development'},@{name='Production'},@{name='JSON'}) {
                param($name)
                Get-BigIPPartition -F5Session $mocksession -Name $name |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'string' }
                    Assert-MockCalled Invoke-RestMethodOverride -Times 1 -Exactly -Scope It -ParameterFilter { $Uri.AbsoluteUri -eq (($mocksession.BaseURL -replace 'ltm/','sys/folder') + ('/~{0}?$select=name,subPath' -f $name)) }
            }
            It "Requests BigIP partitions with Name [-Folder alias] '<name>'" -TestCases @(@{name='Common'}) {
                param($name)
                Get-BigIPPartition -F5Session $mocksession -Folder $name |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'string' }
                    Assert-MockCalled Invoke-RestMethodOverride -Times 1 -Exactly -Scope It -ParameterFilter { $Uri.AbsoluteUri -eq (($mocksession.BaseURL -replace 'ltm/','sys/folder') + ('/~{0}?$select=name,subPath' -f $name)) }
            }
            It "Requests BigIP partitions with Name [-Partition alias] '<name>'" -TestCases @(@{name='Common'}) {
                param($name)
                Get-BigIPPartition -F5Session $mocksession -Partition $name |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'string' }
                    Assert-MockCalled Invoke-RestMethodOverride -Times 1 -Exactly -Scope It -ParameterFilter { $Uri.AbsoluteUri -eq (($mocksession.BaseURL -replace 'ltm/','sys/folder') + ('/~{0}?$select=name,subPath' -f $name)) }
            }
            It "Requests BigIP partitions by Name[]" -TestCases @(@{name=@('Common','Development','Production')}) {
                param($name)
                Get-BigIPPartition -F5Session $mocksession -Name $name |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'string' }
                Assert-MockCalled Invoke-RestMethodOverride -Times 3 -Exactly -Scope It
            }
            It "Requests BigIP partitions by Name From Pipeline" -TestCases @(@{ object = ([pscustomobject]@{name = 'Common'}),([pscustomobject]@{name = 'Development'}) }) {
                param($object)
                $object | Get-BigIPPartition -F5Session $mocksession |
                    ForEach-Object { $_.PSObject.TypeNames[0] | Should Be 'string' }
                Assert-MockCalled Invoke-RestMethodOverride -Times ($object.Count) -Exactly -Scope It
            }
        }
    }
}

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
                    Assert-MockCalled Invoke-RestMethodOverride -Times 1 -Exactly -Scope It -ParameterFilter { $Uri.AbsoluteUri -eq ('{0}monitor/{1}/' -f $mocksession.BaseURL,$type) }
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
Describe 'New-F5Session' -Tags 'Unit' {
    InModuleScope F5-LTM {
        Context "Strict mode PS$($PSVersionTable.PSVersion.Major)" {
            Set-StrictMode -Off

#region Arrange: Initialize Mocks

            # Mocking Invoke-RestMethodOverride for unit testing Module without F5 device connectivity
            Mock Invoke-RestMethodOverride {
                switch ($LTMName) {
                    'version11' {
                        if ($URI -match 'sys/version/') {
                            '{"version":"11.5.1"}'
                        } else {
                            throw '404 Not found'
                        }
                    }
                    Default {
                        if ($URI -match 'mgmt/shared/authn/login') {
                            [pscustomobject]@{token=@{token='dummytoken';starttime=[DateTime]::Now;uuid='9912a8f9-6fa9-474d-b00d-3f16226352b7'}}
                        #} elseif ($URI -match 'mgmt/shared/authz/tokens') {
                            # token extension request currently doesn't have to return anything, just not fail
                        } elseif ($URI -match 'sys/version/') {
                            '{"version":"12.1.0"}'
                        }
                    }
                }
            }
            Mock Invoke-WebRequest { $true }
            
            $credentials = New-Object System.Management.Automation.PSCredential ('georgejetson', (ConvertTo-SecureString 'judyr0ck$!' -AsPlainText -Force))

#endregion Arrange: Initialize Mocks

            It "`$Script:F5Session initialized on 1st call" {
                $testsession = New-F5Session -LTMName 'any' -LTMCredentials $credentials -PassThru
                Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It # Only v11 calls Invoke-WebRequest
                Assert-MockCalled Invoke-RestMethodOverride -Times 2 -Exactly -Scope It
                $Script:F5Session.BaseURL -eq $testsession.BaseURL | Should Be $true
                $Script:F5Session.LTMVersion -eq $testsession.LTMVersion | Should Be $true
            }
            It "`$Script:F5Session overridden with -Default switch" {
                $testsession = New-F5Session -LTMName 'newdefault' -LTMCredentials $credentials -Default -PassThru
                Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It # Only v11 calls Invoke-WebRequest
                Assert-MockCalled Invoke-RestMethodOverride -Times 2 -Exactly -Scope It
                $Script:F5Session.BaseURL -eq $testsession.BaseURL | Should Be $true
                $Script:F5Session.LTMVersion -eq $testsession.LTMVersion | Should Be $true
            }
            It "v11: Authentication with Credentials" {
                $testsession = New-F5Session -LTMName 'version11' -LTMCredentials $credentials -PassThru
                Assert-MockCalled Invoke-WebRequest -Times 1 -Exactly -Scope It # Only v11 calls Invoke-WebRequest
                Assert-MockCalled Invoke-RestMethodOverride -Times 2 -Exactly -Scope It
                $testsession.LTMVersion -eq [Version]'11.5.1' | Should Be $true
            }
            It "v12+: Authentication with X-F5-Auth-Token header" {
                $testsession = New-F5Session -LTMName 'version12' -LTMCredentials $credentials -PassThru
                Assert-MockCalled Invoke-WebRequest -Times 0 -Scope It # Only v11 calls Invoke-WebRequest
                Assert-MockCalled Invoke-RestMethodOverride -Times 2 -Exactly -Scope It
                $testsession.WebSession.Headers.Keys.Contains('X-F5-Auth-Token') | Should Be $true
                $testsession.WebSession.Headers.Keys.Contains('Token-Expiration') | Should Be $true
            }
            It "v12+: Authentication with X-F5-Auth-Token header + custom TokenLifespan" {
                $testsession = New-F5Session -LTMName 'version12' -LTMCredentials $credentials -TokenLifespan 36000 -PassThru
                Assert-MockCalled Invoke-WebRequest -Times 0 -Scope It # Only v11 calls Invoke-WebRequest
                Assert-MockCalled Invoke-RestMethodOverride -Times 3 -Exactly -Scope It #3rd call for TokenLifespan change
                $testsession.WebSession.Headers.Keys.Contains('X-F5-Auth-Token') | Should Be $true
                $testsession.WebSession.Headers.Keys.Contains('Token-Expiration') | Should Be $true
            }
            It "Throws an error if TokenLifespan is out of range" {
                { New-F5Session -LTMName 'version12' -LTMCredentials $credentials -TokenLifespan 60000 } | Should Throw
            }
        }
    }
}