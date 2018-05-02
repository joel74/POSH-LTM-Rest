Function New-ProfileHttp {
<#
.SYNOPSIS
    Create a new profile.

.DESCRIPTION
    Read more about http profiles 
    https://devcentral.f5.com/Wiki/iControlREST.APIRef_tm_ltm_profile_http.ashx
	
.EXAMPLE
    New-Profile -F5Session $F5Session -Name $ProfileName -Partition $Partition -insertXforwardedFor "Enabled"
.EXAMPLE
    New-Profile -F5Session $F5Session -Name "Service1" -Partition "ADO" -insertXforwardedFor "Enabled" 
.EXAMPLE
    Result of RestAPI 
    kind                      : tm:ltm:profile:http:httpstate
    name                      : http_ServiceGB123
    partition                 : ADO
    fullPath                  : /ADO/http_ServiceGB123
    generation                : 7645
    selfLink                  : https://localhost/mgmt/tm/ltm/profile/http/~ADO
    acceptXff                 : Disabled
    appService                : None
    basicAuthRealm            : None
    defaultsFrom              : /Common/http
    defaultsFromReference     : @{link=https://localhost/mgmt/tm/ltm/profile/ht
    description               : None
    encryptCookieSecret       : ****
    encryptCookies            : {}
    enforcement               : @{excessClientHeaders=reject; excessServerHeade
                                truncatedRedirects=Disabled; unknownMethod=Allo
    explicitProxy             : @{badRequestMessage=None; badResponseMessage=no
    fallbackHost              : None
    fallbackStatusCodes       : {}
    headerErase               : None
    headerInsert              : None
    hsts                      : @{includeSubdomains=Enabled; maximumAge=1607040
    insertXforwardedFor       : Enabled
    lwsSeparator              : None
    lwsWidth                  : 80
    oneconnectTransformations : Enabled
    proxyType                 : reverse
    redirectRewrite           : None
    requestChunking           : Preserve
    responseChunking          : Selective
    responseHeadersPermitted  : {}
    serverAgentName           : BigIP
    sflow                     : @{pollInterval=0; pollIntervalGlobal=yes; sampl
    viaHostName               : None
    viaRequest                : Preserve
    viaResponse               : Preserve
    xffAlternativeNames       : {}
#>   
    [cmdletBinding()]
    param (
        $F5Session=$Script:F5Session,
        [Alias('ProfileName')]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,
        [ValidateSet('enabled','disabled')]
        [string]$acceptXff,
        [string]$appService,
        [string]$basicAuthRealm,
        [string]$description,
        [string]$encryptCookieSecret,
        [string[]]$encryptCookies=@(),
        [string]$fallbackHost,
        [string[]]$fallbackStatusCodes=@(),
        [string]$headerErase,
        [string]$headerInsert,
        [ValidateSet('Enabled','Disabled')]
        [string]$insertXforwardedFor,
        [string]$lwsSeparator,
        [int]$lwsWidth,
        [string]$oneconnectTransformations,
        [string]$tmPartition,
        [string]$proxyType,
		[ValidateSet('None','All','Matching','Nodes')]
        [string]$redirectRewrite,
		[ValidateSet('Preserve','Selective','Rechunk')]
        [string]$requestChunking,
		[ValidateSet('Preserve','Selective','Unchunk','Rechunk')]
        [string]$responseChunking,
        [string]$responseHeadersPermitted,
        [string]$serverAgentName,
        [string]$viaHostName,
		[ValidateSet('Remove','Preserve','Append')]
        [string]$viaRequest,
		[ValidateSet('Remove','Preserve','Append')]
        [string]$viaResponse,
        [string]$xffAlternativeNames,
        [string]$Enforcement
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        
    }
    process {
        $URI = ($F5Session.BaseURL + "profile/http")
        foreach ($profilename in $Name) {
            $newitem = New-F5Item -Name $profilename -Partition $Partition 
            #Check whether the specified profile already exists
            If (Test-Profilehttp -F5session $F5Session -Name $newitem.Name -Partition $newitem.Partition){
                Write-Error "The $($newitem.FullPath) profile already exists."
            }
            Else {
                #Start building the JSON for the action
                if($Enforcement -eq $null ){$Enforcement = @{}}
                $JSONBody = @{name=$newitem.Name;partition=$newitem.Partition;acceptXff=$acceptXff;appService=$appService;basicAuthRealm=$basicAuthRealm;defaultsFrom="/Common/http";description=$description;encryptCookieSecret=$encryptCookieSecret;encryptCookies=$encryptCookies;fallbackHost=$fallbackHost;fallbackStatusCodes=$fallbackStatusCodes;headerErase=$headerErase;headerInsert=$headerInsert;insertXforwardedFor=$insertXforwardedFor;lwsSeparator=$lwsSeparator;lwsWidth=$lwsWidth;oneconnectTransformations=$oneconnectTransformations;tmPartition=$tmPartition;proxyType=$proxyType;redirectRewrite=$redirectRewrite;requestChunking=$requestChunking;responseChunking=$responseChunking;responseHeadersPermitted=$responseHeadersPermitted;serverAgentName=$serverAgentName;viaHostName=$viaHostName;viaRequest=$viaRequest;viaResponse=$viaResponse;xffAlternativeNames=$xffAlternativeNames;Enforcement=$Enforcement}
                ($JSONBody.GetEnumerator() | ? Value -eq "" ).name | % {$JSONBody.Remove($_)}
                $JSONBody = $JSONBody | ConvertTo-Json
                Invoke-F5RestMethod -Method POST -Uri "$URI" -F5Session $F5Session -Body $JSONBody -ContentType 'application/json' -ErrorMessage ("Failed to create the $($newitem.FullPath) profile.") -AsBoolean
				Write-Verbose "If viaRequest or viaResponse is set to 'append,' then a value for viaHostName is required."

			}
        }
    }
}
