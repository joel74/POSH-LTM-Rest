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
        
        [Alias('HealthMonitorName')]
        [Alias('MonitorName')]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,
        
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Type,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Receive,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Send,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [int]$Interval=5,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [int]$Timeout=16,

        [switch]
        $Passthru
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }
    process {
        $URI = $F5Session.BaseURL + "monitor/$Type"
        foreach($monitorname in $Name) {
            $newitem = New-F5Item -Name $monitorname -Partition $Partition 
            #Check whether the specified pool already exists
            If (Test-HealthMonitor -F5session $F5Session -Name $newitem.Name -Partition $newitem.Partition -Type $Type){
                Write-Error "The /$Type$($newitem.FullPath) health monitor already exists."
            } else {
                #Start building the JSON for the action
                $JSONBody = @{name=$newitem.Name;partition=$newitem.Partition;recv=$Receive;send=$Send;interval=$Interval;timeout=$Timeout} | 
                    ConvertTo-Json        
                # Caused by a bug in ConvertTo-Json https://windowsserver.uservoice.com/forums/301869-powershell/suggestions/11088243-provide-option-to-not-encode-html-special-characte
                # '<', '>', ''' and '&' are replaced by ConvertTo-Json to \\u003c, \\u003e, \\u0027, and \\u0026. The F5 API doesn't understand this. Change them back.
                $ReplaceChars = @{
                    '\\u003c' = '<'
                    '\\u003e' = '>'
                    '\\u0027' = "'"
                    '\\u0026' = "&"
                }

                foreach ($Char in $ReplaceChars.GetEnumerator()) 
                {
                    $JSONBody = $JSONBody -replace $Char.Key, $Char.Value
                }
                $newmonitor = Invoke-F5RestMethod -Method POST -Uri "$URI" -F5Session $F5Session -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to create the /$Type$($newitem.FullPath) health monitor."
                if ($Passthru) {
                    Get-HealthMonitor -F5Session $F5Session -Name $newmonitor.name -Partition $newmonitor.partition -Type $Type
                }
            }
        }
    }
}
