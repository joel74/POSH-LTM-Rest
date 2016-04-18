Function Get-Partition {
<#
.SYNOPSIS
    Retrieve specified Partition(s)
.NOTES
    Partition names are case-specific.
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,

        [Alias('Folder')]
        [Alias('Partition')]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name=''
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Partition names are case-specific."
    }
    process {
        foreach ($itemname in $Name) {
            $itemname = $itemname -replace '/','~'
            if ($itemname -and ($itemname -notmatch '^~')) {
                $itemname = "~$itemname"
            }
            $URI = ($F5Session.BaseURL -replace 'ltm/','sys/folder') + '/{0}?$select=name,subPath' -f $itemname
            $JSON = Invoke-RestMethodOverride -Method Get -Uri $URI -Credential $F5Session.Credential
            Invoke-NullCoalescing {$JSON.items} {$JSON} | 
                Where-Object { $_.subPath -eq '/' -and ([string]::IsNullOrEmpty($Name) -or $Name -contains $_.name) } |
                    Select-Object -ExpandProperty name
         }
    }
}