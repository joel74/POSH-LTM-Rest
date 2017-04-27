Function New-Application
{
# Assumptions hard coded in this function:
# 1) All application templates contain lists and varables
# 2) Variables and lists do not have encrypted values
# 3) Application templates always use tables to only store pool members
# 
# 
# Also note that this function will ignore errors if the application was
# successfully created, but could not immediately be retrieved
<#
.SYNOPSIS
    Create a new application (iApp)
#>
    [cmdletBinding(SupportsShouldProcess = $True)]
    param (
        $F5Session=$Script:F5Session,

        [Alias('ApplicationName')]
        [Parameter(Mandatory=$true)]
        [string]$Name='',
        
        [Parameter(Mandatory=$false)]
        [string]$Partition='Common',
        
        [Parameter(Mandatory=$true)]
        [string]$StrictUpdates,
        
        [Parameter(Mandatory=$true)]
        [string]$Template,
        
        [Parameter(Mandatory=$true)]
        [Array]$Tables,
        
        [Parameter(Mandatory=$true)]
        [Array]$Lists,
        
        [Parameter(Mandatory=$true)]
        [Array]$Variables
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Application names are case-specific."
    }
    process {        
        
        if($Lists.Count -eq 1)
        {
            $ListsJson = '"lists":  [' + ($Lists | ConvertTo-Json) + ']'
        }
        else
        {
            $ListsJson = '"lists":  ' + ($Lists | ConvertTo-Json)
        }
        
        if($Tables.Count -eq 1)
        {
            $TablesJson = '"tables":  [' + ($Tables | ConvertTo-Json -Depth 4) + ']'
        }
        else
        {
            $TablesJson = '"tables":  ' + ($Tables | ConvertTo-Json -Depth 4)
        }
        
        if($Variables.Count -eq 1)
        {
            $VariablesJson = '"variables":  [' + ($Variables | ConvertTo-Json) + ']'
        }
        else
        {
            $VariablesJson = '"variables":  ' + ($Variables | ConvertTo-Json)
        }
        
        $JSONBody = @"
{
"kind": "tm:sys:application:service:servicestate",
"name": "$Name",
"partition": "$Partition",
"strictUpdates": "$StrictUpdates",
"template": "$Template",
"templateModified": "no",
$ListsJson,
$TablesJson,
$VariablesJson
}
"@
        
        $URI = "$($F5Session.RootURL)/mgmt/tm/sys/application/service/"
        
        if ($PSCmdlet.ShouldProcess($F5Session.Name, "Creating virtualserver $Name"))
        {
            try
            {
                Invoke-F5RestMethod -Method POST -Uri "$URI" `
                  -F5Session $F5Session `
                  -Body $JSONBody `
                  -ContentType 'application/json' `
                  -ErrorMessage "Failed to create the application $Name" `
                  -ErrorAction Stop
            }
            catch
            {
                if($_.Exception.Message -like "*404 Not Found: The configuration was updated successfully but could not be retrieved*")
                {
                    Write-Verbose("Successfully created $Name in $Partition partition, but it could not be retrieved.")
                }
                else
                {
                    Throw($_)
                }
            }
        }
    }
}