<#
.SYNOPSIS
    Similar to the C# ?? operator e.g. name = value ?? String.Empty
.NOTES
    This was extracted from the PSCX module for internal use in this module without requiring a dependency on PSCX.
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
                if ($result -eq $null) {
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
                if ($result -eq $null) {
                    &$AlternateExpr
                }
                else {
                    $result
                }
            }
        }
    }
}