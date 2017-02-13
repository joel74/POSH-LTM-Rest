Function New-F5Item {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [string]$Application,
        [string]$Partition
    )
    $ItemPath = Get-ItemPath -Name $Name -Application $Application -Partition $Partition
    If ($ItemPath -match '^[~/](?<Partition>[^~/]*)[~/]((?<Application>[^~/]*).app[~/])?(?<Name>[^~/]*)$') {
        if ($matches['Application']) {
            [pscustomobject]@{
                application = $matches['Application']
                name        = $matches['Name']
                partition   = $matches['Partition']
                fullPath    = $ItemPath -replace '~','/'
                itempath    = $ItemPath
            }
        } else {
            [pscustomobject]@{
                name      = $matches['Name']
                partition = $matches['Partition']
                fullPath  = $ItemPath -replace '~','/'
                itempath  = $ItemPath
            }
        }
    }
}
