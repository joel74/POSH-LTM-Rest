Function New-F5Item {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [string]$Partition
    )
    if ($Name -match '^/(?<Partition>[^/]*)/(?<Name>[^/]*)$') {
        $Partition = $matches['Partition']
        $Name = $matches['Name']
    }
    if (!$Partition) {
        $Partition = 'Common'
    }
    [pscustomobject]@{Name=$Name; Partition=$Partition; FullPath="/$Partition/$Name"; ItemPath="~$Partition~$Name"; }
}