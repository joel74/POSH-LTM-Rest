Function New-HealthMonitor {
<#
.SYNOPSIS
    Create a new health monitor

.EXAMPLE
    New-HealthMonitor -F5Session $F5Session -Name "/Common/test123" -Type http -Receive '^HTTP.1.[0-2]\s([2|3]0[0-9])' -Send 'HEAD /host.ashx?isup HTTP/1.1\r\nHost: Test123.dyn-intl.com\r\nConnection: close\r\n\r\n'
#>   
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Type,
        [Parameter(Mandatory=$false)][string]$Receive,
        [Parameter(Mandatory=$false)][string]$Send
    )
    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $URI = $F5session.BaseURL + "monitor/$Type"

    #Check whether the specified pool already exists
    If (Test-HealthMonitor -F5session $F5session -Name $Name -Type $Type){
        Write-Error "The $Name pool already exists."
    }

    Else {
        $Partition = 'Common'
        if ($Name -match '^/(?<Partition>[^/]*)/(?<Name>[^/]*)$') {
            $Partition = $matches['Partition']
            $Name = $matches['Name']
        }
        #Start building the JSON for the action
        $JSONBody = @{name=$Name;partition=$Partition;recv=$Receive;send=$Send;interval=5;timeout=16}
        $JSONBody = $JSONBody | ConvertTo-Json

        Invoke-RestMethodOverride -Method POST -Uri "$URI" -Credential $F5session.Credential -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to create the $Name health monitor." -AsBoolean
    }
}
