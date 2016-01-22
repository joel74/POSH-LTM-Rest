# POSH-LTM-Rest
This PowerShell module uses the F5 LTM REST API to manipulate and query pools, pool members, virtual servers and iRules.
It is built to work with version 11.6 and higher

It requires PowerShell v3 or higher.

It includes a Validation.cs class file (based on code posted by Brian Scholer on www.briantist.com) to allow for using the REST API with LTM devices using self-signed SSL certificates.

To use:
Download the three files (F5-LTM.psm1, F5-LTM.psd1 and Validation.cs), and place them in a F5-LTM folder beneath your PowerShell modules folder. By default, this is %USERPROFILE%\Documents\WindowsPowerShell\Modules or $env:UserProfile\Documents\WindowsPowerShell\Modules

The module contains the following functions. 

   * Add-iRuleToVirtualServer
   * Add-PoolMember
   * Disable-PoolMember
   * Enable-PoolMember
   * Get-AllPoolMembersStatus
   * Get-CurrentConnectionCount
   * Get-F5session
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
   * New-Pool
   * New-VirtualServer
   * Remove-iRuleFromVirtualServer
   * Remove-Pool
   * Remove-PoolMember
   * Remove-ProfileRamCache
   * Remove-VirtualServer
   * Set-PoolMemberDescription
   * Test-Functionality
   * Test-Pool
   * Test-VirtualServer

Nearly all of the functions require an F5 session object as a parameter, which contains the base URL for the F5 LTM and a credential object for a user with privileges to manipulate the F5 LTM via the REST API. Use the Get-F5session function to create this object. This function expects the following parameters:
   * The name or IP address of the F5 LTM device
   * A credential object for a user with rights to use the REST API. 
You can create a credential object using 'Get-Credential' and entering the username and password at the prompts, or programmatically like this:
   $secpasswd = ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force
   $mycreds = New-Object System.Management.Automation.PSCredential ("username", $secpasswd)
Thanks to Kotesh Bandhamravuri and his blog entry http://blogs.msdn.com/b/koteshb/archive/2010/02/13/powershell-creating-a-pscredential-object.aspx for this snippet.
	 
There is a function called Test-Functionality that takes an F5Session object, a new pool name, a new virtual server, an IP address for the virtual server, and a computer as a pool member, and validates nearly all the functions in the module.
