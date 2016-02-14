# POSH-LTM-Rest
This PowerShell module uses the F5 LTM REST API to manipulate and query pools, pool members, virtual servers and iRules.
It is built to work with version 11.6 and higher

It requires PowerShell v3 or higher.

It includes a Validation.cs class file (based on code posted by Brian Scholer on www.briantist.com) to allow for using the REST API with LTM devices using self-signed SSL certificates.

To use:
Download all the files and place them in a F5-LTM folder beneath your PowerShell modules folder. By default, this is %USERPROFILE%\Documents\WindowsPowerShell\Modules or $env:UserProfile\Documents\WindowsPowerShell\Modules

The module contains the following functions. 

   * Add-iRuleToVirtualServer
   * Add-PoolMember
   * Disable-PoolMember
   * Enable-PoolMember
   * Get-AllPoolMembersStatus
   * Get-CurrentConnectionCount
   * Get-F5Session (will be deprecated in future versions. Use New-F5Session instead.)
   * Get-F5Status
   * Get-iRuleCollection
   * Get-Pool
   * Get-PoolList
   * Get-PoolMember
   * Get-PoolMemberCollection
   * Get-PoolMemberDescription
   * Get-PoolMemberIP
   * Get-PoolMembers
   * Get-PoolMemberStatus
   * Get-PoolsForMember
   * Get-StatusShape
   * Get-VirtualServer
   * Get-VirtualServeriRuleCollection
   * Get-VirtualServerList
   * New-F5Session
   * New-Pool
   * New-VirtualServer
   * Remove-iRuleFromVirtualServer
   * Remove-Pool
   * Remove-PoolMember
   * Remove-ProfileRamCache
   * Remove-VirtualServer
   * Set-PoolMemberDescription
   * Sync-DeviceToGroup
   * Test-Functionality
   * Test-Pool
   * Test-F5Session
   * Test-VirtualServer

Nearly all of the functions require an F5 session object to manipulate the F5 LTM via the REST API. 
Use the New-F5Session function to create this object. This function expects the following parameters:
   * The name or IP address of the F5 LTM device
   * A credential object for a user with rights to use the REST API. 
   
You can create a credential object using 'Get-Credential' and entering the username and password at the prompts, or programmatically like this:
```
$secpasswd = ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("username", $secpasswd)
```
Thanks to Kotesh Bandhamravuri and his blog entry http://blogs.msdn.com/b/koteshb/archive/2010/02/13/powershell-creating-a-pscredential-object.aspx for this snippet.

The first time New-F5Session is called, it creates a script-scoped $F5Session object that is referenced by the functions that require an F5 session. If an F5 session object is passed to one of these functions, that will be used in place of the script-scoped $F5Session object.

To create a F5 session object to store locally, instead of in the script scope, use the -PassThrough switch when calling New-F5Session, and the function will return the object.
To overwrite the F5 session in the script scope, use the -Default switch when calling New-F5Session.

Currently, the Get-F5session function only allows for basic authentication, so the user must be a local admin on the LTM device, and cannot be an external (i.e. LDAP, Active Directory, RADIUS) user. There is an open issue (#24) for updating the module to allow token-based authentication to accomadate AD users, in addition to basic authentication.

There is a function called Test-Functionality that takes a pool name, a virtual server name, an IP address for the virtual server, and a computer as a pool member, and validates nearly all the functions in the module. Make sure that you don't use an existing pool name or virtual server name.
Here is an example of how to use this function:

```
#Create an F5 session
New-F5Session -LTMName $MyLTM_IP -LTMCredentials $MyLTMCreds
Test-Functionality -TestVirtualServer 'TestVirtServer01' -TestVirtualServerIP $VirtualServerIP -TestPool 'TestPool01' -PoolMember $SomeComputerName
```
