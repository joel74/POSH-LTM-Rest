Function Get-SSLCertificate {
<#
.SYNOPSIS
    Get the SSL Certificates from the device

.NOTES
    Only returns expired or expiring certs at this stage.
#>
    [CmdletBinding()]
    Param (
        $F5Session=$Script:F5Session
    )

    #Test that the F5 session is in a valid format
    Test-F5Session($F5Session)

    $URI = $F5Session.BaseURL -replace "/ltm", "/sys"

    $JSONBody = @{command='run';utilCmdArgs="crypto check-cert verbose enabled"}
    $JSONBody = $JSONBody | ConvertTo-Json

    $JSON = Invoke-F5RestMethod -Method POST -Uri "$URI" -F5Session $F5Session -Body $JSONBody -ContentType 'application/json' -ErrorMessage "Failed to retrieve SSL Certs"

    # Regex returns expiring / or expired certss fully appreciate room for improvement
    $pattern = "CN=(?<CommonName>.*?),.*? in file (?<FilePath>.*?) (?<Status>expired on|will expire on) (?<ExpiryDate>\w{3} \d{1,2} \d{2}:\d{2}:\d{2} \d{4}) ?(?:GMT)?"

    $matches = [regex]::Matches($json.CommandResult, $pattern)

    ForEach ($match in $matches) {
        $status = if ($match.Groups["Status"].Value -eq "expired on") { "expired" } else { "expiring" }

        [PSCustomObject]@{
            CommonName = $match.Groups["CommonName"].Value
            FilePath = $match.Groups["FilePath"].Value
            ExpiryDate = [datetime]::ParseExact($match.Groups["ExpiryDate"].Value, "MMM dd HH:mm:ss yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
            Status = $status
        }
    }
}
