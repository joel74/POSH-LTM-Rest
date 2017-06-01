# POSH-LTM-Rest
This PowerShell module uses the F5 LTM REST API to manipulate and query pools, pool members, virtual servers and iRules.
It is built to work with the following BIG-IP versions:
   * 11.5.1 Build 8.0.175 Hotfix 8 and later
   * 11.6.0 Build 5.0.429 Hotfix 4 and later
   * All versions of 12.x

It requires PowerShell v3 or higher.

It includes a Validation.cs class file (based on code posted by Brian Scholer on www.briantist.com) to allow for using the REST API with LTM devices using self-signed SSL certificates.

Setup:
Install the latest version of the module either by calling 'Install-Module F5-LTM' to retrieve it from the PowerShell Gallery (assuming you're using PSGet, included in PowerShell 5 and later). By default, PSGallery is an untrusted repository, so you may be prompted for confirmation. If you don't have PowerShell 5 / PSGet, use the Gist install script available at https://gist.github.com/joel74/f5acb78ca7dbe0d87bc95cab98de1388

The module contains the following functions.

   * Add-iRuleToVirtualServer
   * Add-PoolMember
   * Add-PoolMonitor
   * Disable-PoolMember
   * Disable-VirtualServer
   * Enable-PoolMember
   * Enable-VirtualServer
   * Get-Application
   * Get-CurrentConnectionCount (deprecated; use __Get-PoolMemberStats | Select-Object -ExpandProperty 'serverside.curConns'__)
   * Get-F5Session (will be deprecated in future versions. use __New-F5Session__)
   * Get-F5Status
   * Get-HealthMonitor
   * Get-HealthMonitorType
   * Get-iRule
   * Get-iRuleCollection (deprecated; use __Get-iRule__)
   * Get-Node
   * Get-BIGIPPartition
   * Get-Pool
   * Get-PoolList (deprecated; use __Get-Pool__)
   * Get-PoolMember
   * Get-PoolMemberCollection (deprecated; use __Get-PoolMember__)
   * Get-PoolMemberCollectionStatus
   * Get-PoolMemberDescription (deprecated; use __Get-PoolMember__)
   * Get-PoolMemberIP (deprecated; use __Get-PoolMember__)
   * Get-PoolMembers (deprecated; use __Get-PoolMember__)
   * Get-PoolMemberStats
   * Get-PoolMemberStatus (deprecated; use __Get-PoolMember__)
   * Get-PoolMonitor
   * Get-PoolsForMember
   * Get-StatusShape
   * Get-VirtualServer
   * Get-VirtualServeriRuleCollection (deprecated; use __Get-VirtualServer | Where rules | Select -ExpandProperty rules__)
   * Get-VirtualServerList (deprecated; use __Get-VirtualServer__) 
   * Invoke-RestMethodOverride
   * New-Application
   * New-F5Session
   * New-HealthMonitor
   * New-Node
   * New-Pool
   * New-VirtualServer
   * Remove-Application
   * Remove-HealthMonitor
   * Remove-iRule
   * Remove-iRuleFromVirtualServer
   * Remove-Pool
   * Remove-PoolMember
   * Remove-PoolMonitor
   * Remove-ProfileRamCache
   * Remove-Node
   * Remove-VirtualServer
   * Set-iRule
   * Set-PoolLoadBalancingMode (deprecated; use __Set-Pool__)
   * Set-PoolMemberDescription
   * Set-Pool
   * Set-VirtualServer
   * Sync-DeviceToGroup
   * Test-F5Session
   * Test-Functionality
   * Test-HealthMonitor
   * Test-Node
   * Test-Pool
   * Test-VirtualServer

Nearly all of the functions require an F5 session object to manipulate the F5 LTM via the REST API.
use the New-F5Session function to create this object. This function expects the following parameters:
   * The name or IP address of the F5 LTM device
   * A credential object for a user with rights to use the REST API.

You can create a credential object using 'Get-Credential' and entering the username and password at the prompts, or programmatically like this:
```
$secpasswd = ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential "username", $secpasswd
```
Thanks to Kotesh Bandhamravuri and his blog entry http://blogs.msdn.com/b/koteshb/archive/2010/02/13/powershell-creating-a-pscredential-object.aspx for this snippet.

The first time New-F5Session is called, it creates a script-scoped $F5Session object that is referenced by the functions that require an F5 session. If an F5 session object is passed to one of these functions, that will be used in place of the script-scoped $F5Session object.

To create a F5 session object to store locally, instead of in the script scope, use the -PassThrough switch when calling New-F5Session, and the function will return the object.
To overwrite the F5 session in the script scope, use the -Default switch when calling New-F5Session.

There is a function called Test-Functionality that takes a pool name, a virtual server name, an IP address for the virtual server, and a computer as a pool member, and validates nearly all the functions in the module. Make sure that you don't use an existing pool name or virtual server name.
Here is an example of how to use this function:

```
#Create an F5 session
New-F5Session -LTMName $MyLTM_IP -LTMCredentials $MyLTMCreds
Test-Functionality -TestVirtualServer 'TestVirtServer01' -TestVirtualServerIP $VirtualServerIP -TestPool 'TestPool01' -PoolMember $SomeComputerName
```
