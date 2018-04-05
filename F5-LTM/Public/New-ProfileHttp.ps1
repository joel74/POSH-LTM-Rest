Function New-ProfileHttp {
<#
.SYNOPSIS
    Create a new profile.

.DESCRIPTION
    readmore about f5 Api
    https://devcentral.f5.com/Wiki/iControlREST.APIRef_tm_ltm_profile_http.ashx

.EXAMPLE
    New-Profile -F5Session $F5Session -Name $ProfilName -Partition $Partition -insertXforwardedFor "enabled"
.EXAMPLE
    New-Profile -F5Session $F5Session -Name "Service1" -Partition "ADO" -insertXforwardedFor "enabled" 
.EXAMPLE
    Result of RestAPI 
    kind                      : tm:ltm:profile:http:httpstate
    name                      : http_ServiceGB123
    partition                 : ADO
    fullPath                  : /ADO/http_ServiceGB123
    generation                : 7645
    selfLink                  : https://localhost/mgmt/tm/ltm/profile/http/~ADO
    acceptXff                 : disabled
    appService                : none
    basicAuthRealm            : none
    defaultsFrom              : /Common/http
    defaultsFromReference     : @{link=https://localhost/mgmt/tm/ltm/profile/ht
    description               : none
    encryptCookieSecret       : ****
    encryptCookies            : {}
    enforcement               : @{excessClientHeaders=reject; excessServerHeade
                                truncatedRedirects=disabled; unknownMethod=allo
    explicitProxy             : @{badRequestMessage=none; badResponseMessage=no
    fallbackHost              : none
    fallbackStatusCodes       : {}
    headerErase               : none
    headerInsert              : none
    hsts                      : @{includeSubdomains=enabled; maximumAge=1607040
    insertXforwardedFor       : enabled
    lwsSeparator              : none
    lwsWidth                  : 80
    oneconnectTransformations : enabled
    proxyType                 : reverse
    redirectRewrite           : none
    requestChunking           : preserve
    responseChunking          : selective
    responseHeadersPermitted  : {}
    serverAgentName           : BigIP
    sflow                     : @{pollInterval=0; pollIntervalGlobal=yes; sampl
    viaHostName               : none
    viaRequest                : preserve
    viaResponse               : preserve
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
        [string]$acceptXff,
        [string]$appService,
        [string]$basicAuthRealm,
        [string]$description,
        [string]$encryptCookieSecret,
        [string]$encryptCookies,
        [string]$fallbackHost,
        [string]$fallbackStatusCodes,
        [string]$headerErase,
        [string]$headerInsert,
        [ValidateSet('enabled','disabled')]
        [string]$insertXforwardedFor,
        [string]$lwsSeparator,
        [int]$lwsWidth,
        [string]$oneconnectTransformations,
        [string]$tmPartition,
        [string]$proxyType,
        [string]$redirectRewrite,
        [string]$requestChunking,
        [string]$responseChunking,
        [string]$responseHeadersPermitted,
        [string]$serverAgentName,
        [string]$viaHostName,
        [string]$viaRequest,
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
                ($JSONBody.GetEnumerator() | ? Value -eq "" ).name | % {$JSONBody.remove($_)}
                $JSONBody = $JSONBody | ConvertTo-Json
                Invoke-F5RestMethod -Method POST -Uri "$URI" -F5Session $F5Session -Body $JSONBody -ContentType 'application/json' -ErrorMessage ("Failed to create the $($newitem.FullPath) profile.") -AsBoolean
            }
        }
    }
}
