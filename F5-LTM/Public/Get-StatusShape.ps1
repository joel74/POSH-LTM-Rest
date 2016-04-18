Function Get-StatusShape {
<#
.SYNOPSIS
    Determine the shape to display for a member's current state and session values
#>
    [cmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory=$true)]$state,
        [Parameter(Mandatory=$true)]$session
    )

    #Determine status shape based on state and session values
    If ($state -eq "up" -and $session -eq "monitor-enabled"){
        $StatusShape = "green-circle"
    }
    ElseIf ($state -eq "up" -and $session -eq "user-disabled"){
        $StatusShape = "black-circle"
    }
    ElseIf ($state -eq "user-down" -and $session -eq "user-disabled"){
        $StatusShape = "black-diamond"
    }
    ElseIf ($state -eq "down" -and $session -eq "monitor-enabled"){
        $StatusShape = "red-diamond"
    }
    ElseIf ($state -eq "unchecked" -and $session -eq "user-enabled"){
        $StatusShape = "blue-square"
    }
    ElseIf ($state -eq "unchecked" -and $session -eq "user-disabled"){
        $StatusShape = "black-square"
    }
    Else{
        #Unknown
        $StatusShape = "black-square"
    }

    $StatusShape
}
