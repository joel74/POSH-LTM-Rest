Function Get-Application
{
<#
.SYNOPSIS
    Retrieve specified application(s) (iApp)
#>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,

        [Alias('ApplicationName')]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Application names are case-specific."
    }
    process {
        if($Name -and $Partition)
        {
            foreach ($itemname in $Name) {
                $URI = "$($F5Session.DeviceURL)/mgmt/tm/sys/application/service/~$($Partition)~$($itemname).app~$($itemname)?expandSubcollections=true"
                $JSON = Invoke-F5RestMethod -Method Get -Uri $URI -F5Session $F5Session
                if ($JSON.items -or $JSON.name) {
                    $items = Invoke-NullCoalescing {$JSON.items} {$JSON}
                    $items | Add-ObjectDetail -TypeName 'PoshLTM.Application'
                }
            }
        }
        elseif($Name)
        {
            foreach ($itemname in $Name) {
                $URI = "$($F5Session.DeviceURL)/mgmt/tm/sys/application/service/?expandSubcollections=true"
                $JSON = Invoke-F5RestMethod -Method Get -Uri $URI -F5Session $F5Session
                if ($JSON.items -or $JSON.name) {
                    $items = Invoke-NullCoalescing {$JSON.items} {$JSON}
                    $items = $items | ? {$_.name -eq $itemname}
                    $items | Add-ObjectDetail -TypeName 'PoshLTM.Application'
                }
            }
        }
        elseif($Partition)
        {
            $URI = "$($F5Session.DeviceURL)/mgmt/tm/sys/application/service/?expandSubcollections=true"
            $JSON = Invoke-F5RestMethod -Method Get -Uri $URI -F5Session $F5Session
            if ($JSON.items -or $JSON.name) {
                $items = Invoke-NullCoalescing {$JSON.items} {$JSON}
                $items = $items | ? {$_.partition -eq $Partition}
                $items | Add-ObjectDetail -TypeName 'PoshLTM.Application'
            }
        }
        else
        {
            $URI = "$($F5Session.DeviceURL)/mgmt/tm/sys/application/service/?expandSubcollections=true"
            $JSON = Invoke-F5RestMethod -Method Get -Uri $URI -F5Session $F5Session
            if ($JSON.items -or $JSON.name) {
                $items = Invoke-NullCoalescing {$JSON.items} {$JSON}
                $items | Add-ObjectDetail -TypeName 'PoshLTM.Application'
            }
        }
    }
}
Set-Alias -Name Get-iApp -Value Get-Application
