Function Get-ItemPath {
    param (
        [Parameter(Mandatory=$false)][string]$Name,
        [Parameter(Mandatory=$false)][string]$Partition
    )
    if ($Name -match '^/.*/.*$') {
        $Name -replace '/','~'
    } else {
        if ([string]::IsNullOrEmpty($Name)) {
            if ([string]::IsNullOrEmpty($Partition)) {
                ''
            } else {
                "?`$filter=partition eq $Partition"
            }
        } else {
            if ([string]::IsNullOrEmpty($Partition)) {
                "~Common~$Name"
            } else {
               "~$Partition~$Name"
            }
        }
    }
}
