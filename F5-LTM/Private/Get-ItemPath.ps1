Function Get-ItemPath {
    param (
        [Parameter(Mandatory=$false)][string]$Name,
        [Parameter(Mandatory=$false)][string]$Application,
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
                if ([string]::IsNullOrEmpty($Application)) {
                    "~Common~$Name"
                }
                else {
                    "~Common~$Application.app~$Name"
                }
            } else {
                if ([string]::IsNullOrEmpty($Application)) {
                    "~$Partition~$Name"
                }
                else {
                    "~$Partition~$Application.app~$Name"
                }
            }
        }
    }
}
