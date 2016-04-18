<#
.SYNOPSIS
    Returns the first argument -ne $null, or $null if all arguments are $null.  Similar to the C# ?? operator e.g. name = value ?? String.Empty
.NOTES
    This was extracted from the PSCX module for internal use in this module without requiring a dependency on PSCX.
.LINK
https://github.com/flofreud/pscx/blob/master/about_Pscx.help.txt
.LINK
https://msdn.microsoft.com/en-us/library/ms173224.aspx
.LINK
https://msdn.microsoft.com/en-us/library/ms173224.aspx
#>
Function Invoke-NullCoalescing {
    param(
        [Parameter(Mandatory, Position=0)]
        [AllowNull()]
        [scriptblock]
        $PrimaryExpr,

        [Parameter(Mandatory, Position=1)]
        [scriptblock]
        $AlternateExpr,

        [Parameter(ValueFromPipeline, ParameterSetName='InputObject')]
        [psobject]
        $InputObject
    ) 
        
    Process { 
        if ($pscmdlet.ParameterSetName -eq 'InputObject') {
            if ($PrimaryExpr -eq $null) {
                Foreach-Object $AlternateExpr -InputObject $InputObject
            }
            else {
                $result = Foreach-Object $PrimaryExpr -input $InputObject
                if ($null -eq $result) {
                    Foreach-Object $AlternateExpr -InputObject $InputObject
                }
                else {
                    $result
                }
            }
        }
        else {
            if ($PrimaryExpr -eq $null) {
                &$AlternateExpr
            }
            else {
                $result = &$PrimaryExpr
                if ($null -eq $result) {
                    &$AlternateExpr
                }
                else {
                    $result
                }
            }
        }
    }
}
