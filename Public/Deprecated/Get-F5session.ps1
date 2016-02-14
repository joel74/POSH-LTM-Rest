Function Get-F5session{
<#
.SYNOPSIS
    Get-F5session is deprecated.  Please use New-F5Session
#>
    param(
        [Parameter(Mandatory=$true)][string]$LTMName,
        [Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$LTMCredentials
    )
    Write-Warning "Get-F5session is deprecated.  Please use New-F5Session"
    New-F5Session -LTMName $LTMName -LTMCredentials $LTMCredentials
}