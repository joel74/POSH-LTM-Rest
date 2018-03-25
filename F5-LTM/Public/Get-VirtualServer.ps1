Function Get-VirtualServer{
    <#
        .SYNOPSIS
            Retrieve specified virtual server(s)

        .EXAMPLE
            #Retrieve all virtual servers with a list of assigned iRules for each
            $VS_iRules = Get-VirtualServer |
                ForEach {
                    New-Object psobject -Property @{
                        Name = $_.name;
                        Partition = $_.partition;
                        Rules = @{}
                    }
                }

            $VS_iRules | ForEach { $_.Rules = (Get-VirtualServer -Name $_.Name -Partition $_.Partition | Select-Object -ExpandProperty rules -ErrorAction SilentlyContinue  ) } 

    #>
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,

        [Alias("VirtualServerName")]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name='',

        [Alias('iApp')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Application='',

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Virtual server names are case-specific."
    }
    process {
        foreach ($itemname in $Name) {
            $URI = $F5Session.BaseURL + 'virtual/{0}' -f (Get-ItemPath -Name $itemname -Application $Application -Partition $Partition)
            $JSON = Invoke-F5RestMethod -Method Get -Uri $URI -F5Session $F5Session
            if ($JSON.items -or $JSON.name) {
                $items = Invoke-NullCoalescing {$JSON.items} {$JSON}
                if(![string]::IsNullOrWhiteSpace($Application)) {
                    $items = $items | Where-Object {$_.fullPath -eq "/$($_.partition)/$Application.app/$($_.name)"}
                }
                $items | Add-ObjectDetail -TypeName 'PoshLTM.VirtualServer'
            }
        }
    }
}
