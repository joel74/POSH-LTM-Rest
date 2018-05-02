Function Resolve-NestedStats {
<#
.SYNOPSIS
    Between v11.6 and v12.0, there were breaking changes in regards to the JSON format returned for various iControlREST requests, such as when retrieving the system version or pool member stats.
    Specifically, instead of the data existing in an "entries" property directly underneath the parent JSON object, it is now enclosed in "nestedStats" property within a custom PS object whose name resembles a self-link with the member name repeated.
 
    To resolve this discrepancy, this function performs version-specific transformations to the JSON data and returns it in a standardized format with the "entries" property at the top.
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    param (
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory=$true)][string]$JSONData
    )
    switch ($F5Session.LTMVersion.Major)
    {
        11 { <# no conversion needed #> }
        12 { $JSON = $JSON.entries.PSObject.Properties.Value.nestedStats; }
        13 { $JSON = $JSON.entries.PSObject.Properties.Value.nestedStats; }
        Default { <# assume no conversion needed #> }
    }

    $JSON
}