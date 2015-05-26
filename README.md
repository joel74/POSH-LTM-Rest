# POSH-LTM-Rest
This PowerShell module uses the F5 LTM REST API to manipulate and query pools and pool members. 
It is built to work with version 11.6.

It requires PowerShell v3 or higher.

It depends on the TunableSSLValidator module (https://github.com/Jaykul/Tunable-SSL-Validator) to allow for using the REST API with LTM devices using self-signed SSL certificates.
If you are not connecting to your LTM(s) via SSL or you're using a trusted certificate, then the TunableSSLValidator module is not needed and you can remove the -Insecure parameter from the Invoke-WebRequest calls

To use:
Download the F5-LTM.psm1 and F5-LTM.psd1 files, and place them in a F5-LTM folder beneath your PowerShell modules folder. By default, this is C:\Documents\WindowsPowerShell\Modules or C:\$env:UserProfile\Documents\WindowsPowerShell\Modules

The module contains the following functions. 

   * Add-PoolMember
   * Disable-PoolMemberForced
   * Disable-PoolMember
   * Enable-PoolMember
   * Get-AllPoolMembersStatus
   * Get-CurrentConnections
   * Get-F5session
   * Get-PoolMember
   * Get-PoolMemberIP
   * Get-PoolMemberStatus
   * Get-PoolMembers
   * Get-Pools
   * Get-PoolsForMember
   * Get-StatusShape
   * Remove-PoolMember
   * Set-PoolMemberDescription
   * Test-F5IsActive

Nearly all of the functions require an F5 session object as a parameter, which will contain the base URL for the F5 LTM and a credential object for a user with privileges to manipulate the F5 LTM via the REST API. Use the Get-F5session function to create this object.
