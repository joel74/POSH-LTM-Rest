<#
.SYNOPSIS  
    A module for using the F5 LTM REST API to administer an LTM device
.DESCRIPTION  
    This module uses the F5 LTM REST API to manipulate and query pools, pool members, virtual servers and iRules
    It is built to work with version 11.6 and higher
.NOTES  
    File Name    : F5-LTM.psm1
    Author       : Joel Newton - jnewton@springcm.com
    Requires     : PowerShell V3
    Dependencies : It includes a Validation.cs class file (based on code posted by Brian Scholer) to allow for using the REST API 
    with LTM devices using self-signed SSL certificates.
#>

$Script:F5Session=$null

Add-Type -Path "${PSScriptRoot}\Validation.cs"
#Only add this type if it isn't already added to the session
if (!("PoshLTM.F5Address" -as [type])) {
    Add-Type -Path "${PSScriptRoot}\TypeData\PoshLTM.Types.cs"
}
Update-FormatData "${PSScriptRoot}\TypeData\PoshLTM.Format.ps1xml"
$ScriptPath = Split-Path $MyInvocation.MyCommand.Path

#Restrict .NET Framework to TLS v 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#region Load Public Functions

    Get-ChildItem "$ScriptPath\Public" -Filter *.ps1 -Recurse| Select-Object -Expand FullName | ForEach-Object {
        $Function = Split-Path $_ -Leaf
        try {
            . $_
        } catch {
            Write-Warning ("{0}: {1}" -f $Function,$_.Exception.Message)
        }
   }

#endregion

#region Load Private Functions

    Get-ChildItem "$ScriptPath\Private" -Filter *.ps1 -Recurse | Select-Object -Expand FullName | ForEach-Object {
        $Function = Split-Path $_ -Leaf
        try {
            . $_
        } catch {
            Write-Warning ("{0}: {1}" -f $Function,$_.Exception.Message)
        }
    }

#endregion