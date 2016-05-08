function Get-CompleteSession {
    param($boundSession)
    Invoke-NullCoalescing {$boundSession} {$Script:F5Session}
}
function CompleteMonitorName {
    param($commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters)
    $Session = Get-CompleteSession $fakeBoundParameters.F5Session    
    if ($Session) {
        Get-HealthMonitor -F5Session $Session -Partition $fakeBoundParameters.Partition -Type $fakeBoundParameters.Type | Where-Object { $_.name -like "$wordToComplete*" } | ForEach-Object {
            if ($fakeBoundParameters.Partition) {
                $_.name
            } else {
                $_.fullPath 
            }
        } 
    }
}
function CompleteMonitorType {
    param($commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters)
    $Session = Get-CompleteSession $fakeBoundParameters.F5Session         
    if ($Session) {
        Get-HealthMonitorType -F5Session $Session | Where-Object { $_ -like "$wordToComplete*" }
    }
}
function CompleteNodeAddress {
    param($commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters)
    $Session = Get-CompleteSession $fakeBoundParameters.F5Session    
    if ($Session) {
        Get-Node -F5Session $Session -Partition $fakeBoundParameters.Partition | 
        Where-Object { $_.address -like "$wordToComplete*" } | 
        Select-Object -ExpandProperty address
    }
}
function CompleteNodeName {
    param($commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters)
    $Session = Get-CompleteSession $fakeBoundParameters.F5Session    
    if ($Session) {
        Get-Node -F5Session $Session -Partition $fakeBoundParameters.Partition | Where-Object { $_.name -like "$wordToComplete*" } | ForEach-Object {
            if ($fakeBoundParameters.Partition) {
                $_.name
            } else {
                $_.fullPath 
            }
        } 
    }
}
function CompletePartition {
    param($commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters)
    $Session = Get-CompleteSession $fakeBoundParameters.F5Session    
    if ($Session) {
        Get-Partition -F5Session $Session | Where-Object { $_ -like "$wordToComplete*" }
    }
}
function CompletePoolMemberAddress {
    param($commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters)
    if ($fakeBoundParameters.PoolName) {
        $Session = Get-CompleteSession $fakeBoundParameters.F5Session    
        if ($Session) {
            Get-PoolMember -F5Session $Session -PoolName $fakeBoundParameters.PoolName -Partition $fakeBoundParameters.Partition -Name (Invoke-NullCoalescing {$fakeBoundParameters.Name} {'*'})  | 
                Where-Object { $_.address -like "$wordToComplete*" } | 
                Select-Object -ExpandProperty address
        }
    }
}
function CompletePoolMemberName {
    param($commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters)
    if ($fakeBoundParameters.PoolName) {
        $Session = Get-CompleteSession $fakeBoundParameters.F5Session    
        if ($Session) {
            Get-PoolMember -F5Session $Session -PoolName $fakeBoundParameters.PoolName -Partition $fakeBoundParameters.Partition -Address (Invoke-NullCoalescing {$fakeBoundParameters.Address} {'*'})  | 
                Where-Object { $_.name -like "$wordToComplete*" } | 
                Select-Object -ExpandProperty name
        }
    }
}
function CompletePoolMonitorName {
    param($commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters)
    if ($fakeBoundParameters.PoolName) {
        $Session = Get-CompleteSession $fakeBoundParameters.F5Session    
        if ($Session) {
            Get-PoolMonitor -F5Session $Session -PoolName $fakeBoundParameters.PoolName -Partition $fakeBoundParameters.Partition | 
                Where-Object { $_.name -match "\b$wordToComplete*" } | 
                Select-Object -ExpandProperty name
        }
    }
}
function CompletePoolName {
    param($commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters)
    $Session = Get-CompleteSession $fakeBoundParameters.F5Session    
    if ($Session) {
        Get-Pool -F5Session $Session -Partition $fakeBoundParameters.Partition | Where-Object { $_.name -like "$wordToComplete*" -or $_.fullPath -like "$wordToComplete*" } | ForEach-Object {
            if ($fakeBoundParameters.Partition) {
                $_.name
            } else {
                $_.fullPath 
            }
        } 
    }
}
function CompleteRuleName {
    param($commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters)
    $Session = Get-CompleteSession $fakeBoundParameters.F5Session    
    if ($Session) {
        Get-iRule -F5Session $Session -Partition $fakeBoundParameters.Partition | Where-Object { $_.name -like "$wordToComplete*" -or $_.fullPath -like "$wordToComplete" } | ForEach-Object {
            if ($fakeBoundParameters.Partition) {
                $_.name
            } else {
                $_.fullPath 
            }
        } 
    }
}
function CompleteVirtualServerName {
    param($commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters)
    $Session = Get-CompleteSession $fakeBoundParameters.F5Session    
    if ($Session) {
        Get-VirtualServer -F5Session $Session -Partition $fakeBoundParameters.Partition | Where-Object { $_.name -like "$wordToComplete*" -or $_.fullPath -like "$wordToComplete" } | ForEach-Object {
            if ($fakeBoundParameters.Partition) {
                $_.name
            } else {
                $_.fullPath 
            }
        } 
    }
}
if (Get-Command Register-ArgumentCompleter -ErrorAction Ignore)
{
    Register-ArgumentCompleter `
        -CommandName @(Get-Command '*-PoolMember' -Module F5-LTM) `
        -ParameterName Address `
        -ScriptBlock $function:CompletePoolMemberAddress

    Register-ArgumentCompleter `
        -CommandName @(Get-Command '*-PoolMember' -Module F5-LTM) `
        -ParameterName Name `
        -ScriptBlock $function:CompletePoolMemberName

    Register-ArgumentCompleter `
        -CommandName @(Get-Command '*-PoolMonitor' -Module F5-LTM) `
        -ParameterName Name `
        -ScriptBlock $function:CompletePoolMonitorName

    Register-ArgumentCompleter `
        -CommandName @(Get-Command '*-HealthMonitor' -Module F5-LTM) `
        -ParameterName Name `
        -ScriptBlock $function:CompleteMonitorName

    Register-ArgumentCompleter `
        -CommandName @(Get-Command '*-HealthMonitor' -Module F5-LTM) `
        -ParameterName Type `
        -ScriptBlock $function:CompleteMonitorType

    Register-ArgumentCompleter `
        -CommandName @(Get-Command '*-Node' -Module F5-LTM) `
        -ParameterName Address `
        -ScriptBlock $function:CompleteNodeAddress

    Register-ArgumentCompleter `
        -CommandName @(Get-Command '*-Node' -Module F5-LTM) `
        -ParameterName Name `
        -ScriptBlock $function:CompleteNodeName

    Register-ArgumentCompleter `
        -CommandName @(Get-Command '*-Pool' -Module F5-LTM) `
        -ParameterName Name `
        -ScriptBlock $function:CompletePoolName

    Register-ArgumentCompleter `
        -CommandName @(Get-Command '*' -Module F5-LTM) `
        -ParameterName Partition `
        -ScriptBlock $function:CompletePartition
        
    Register-ArgumentCompleter `
        -CommandName @(Get-Command 'Get-Partition' -Module F5-LTM) `
        -ParameterName Name `
        -ScriptBlock $function:CompletePartition
        
    Register-ArgumentCompleter `
        -CommandName @(Get-Command '*-Pool*' -Module F5-LTM) `
        -ParameterName PoolName `
        -ScriptBlock $function:CompletePoolName
        
    Register-ArgumentCompleter `
        -CommandName @(Get-Command 'Get-iRule' -Module F5-LTM) `
        -ParameterName Name `
        -ScriptBlock $function:CompleteRuleName

    Register-ArgumentCompleter `
        -CommandName @(Get-Command '*-VirtualServer' -Module F5-LTM) `
        -ParameterName Name `
        -ScriptBlock $function:CompleteVirtualServerName
}
Else {

    Write-Verbose "The Register-ArgumentCompleter cmdlet requires either PowerShell v5+ or the installation of the TabExpansionPlusPlus module (https://github.com/lzybkr/TabExpansionPlusPlus)"

}