Function New-VirtualServer
{
  <#
      .SYNOPSIS
      Create a new virtual server
  #>
  [cmdletbinding(SupportsShouldProcess = $True,DefaultParameterSetName="VlanEnabled")]
  param (
    $F5Session = $Script:F5Session
    ,
    [Parameter(Mandatory = $false)]$Kind = 'tm:ltm:virtual:virtualstate'
    ,
    [Parameter(Mandatory = $True)]
    [Alias('VirtualServerName')]
    [string]$Name
    ,

    [Alias('iApp')]
    [Parameter(Mandatory=$false)]
    [string]$Application='',

    [Parameter(Mandatory = $false)]
    [string]$Partition
    ,
    [Parameter(Mandatory = $false)]
    $Description = $null
    ,
    [Parameter(Mandatory = $True)]
    [PoshLTM.F5Address]$DestinationIP
    ,
    [Parameter(Mandatory = $True)]
    $DestinationPort
    ,
    [Parameter(Mandatory = $false, ParameterSetName = 'VlanEnabled')]
    [string[]]$VlanEnabled
    ,
    [Parameter(Mandatory = $false, ParameterSetName = 'VlanDisabled')]
    [string[]]$VlanDisabled
    ,
    [Parameter(Mandatory = $false)]
    $Source = '0.0.0.0/0'
    ,
    [Parameter(Mandatory = $false)]
    $DefaultPool = $null
    ,
    [Parameter(Mandatory = $false)]
    [string[]]$ProfileNames = $null
    ,
    [Parameter(Mandatory = $True)]
    [ValidateSet('tcp','udp','sctp')]
    $ipProtocol = $null
    ,
    [Parameter(Mandatory = $false)]
    $Mask = '255.255.255.255'
    ,
    [Parameter(Mandatory = $false)]
    $ConnectionLimit = '0'
    ,
    [Parameter(Mandatory = $false)]
    [ValidateSet('true','false')]
    $Enabled = 'true'
    ,
    [Parameter(Mandatory = $false)]
    [ValidateSet('automap','snat','none')]
    $SourceAddressTranslationType
    ,
    [Parameter(Mandatory = $false)]
    [string]$SourceAddressTranslationPool
    ,
    [Parameter(Mandatory = $false)]
    [string[]]$PersistenceProfiles
    ,
    [Parameter(Mandatory = $false)]
    [string]$FallbackPersistence


  )

  #Test that the F5 session is in a valid format
  Test-F5Session($F5Session)

  $URI = ($F5Session.BaseURL + 'virtual')

  #Check whether the specified virtual server already exists
  If (Test-VirtualServer -F5session $F5Session -Name $Name)
  {
    Write-Error -Message "The $Name virtual server already exists."
  }
  Else
  {
    $newitem = New-F5Item -Name $Name -Application $Application -Partition $Partition

    #Start building the JSON for the action
    $Destination = $DestinationIP.ToString() + ':' + $DestinationPort
    $JSONBody = @{
      kind                     = $Kind
      name                     = $newitem.Name
      description              = $Description
      partition                = $newitem.Partition
      destination              = $Destination
      source                   = $Source
      pool                     = $DefaultPool
      ipProtocol               = $ipProtocol
      mask                     = $Mask
      connectionLimit          = $ConnectionLimit
      persist                  = $PersistenceProfiles
      fallbackPersistence      = $FallbackPersistence

    }
    if ($newItem.application) {
      $JSONBody.Add('application',$newItem.application)
    }

    #Extra options for Vlan handling. Sets Vlans for VirtualServer, and sets it to be en- or disabled on those Vlans.
    If ($VlanEnabled)
    {
      $JSONBody.vlans = $VlanEnabled
      $JSONBody.vlansEnabled = $True
    }
    elseif ($VlanDisabled)
    {
      $JSONBody.vlans = $VlanDisabled
      $JSONBody.vlansDisabled = $True
    }

    if ($Enabled -eq 'true'){
        $JSONBody.enabled = $True
    }
    elseif ($Enabled -eq 'false'){
        $JSONBody.disabled = $True
    }

    #Settings for source address translation
    If ($SourceAddressTranslationType){
      $SourceAddressTranslation = @{
        type = $SourceAddressTranslationType
      }
      #If SourceAddressTranslationType is SNAT, then a value for sourceAddressTranslationPool is expected
      if ($SourceAddressTranslationType -eq 'snat'){
        $SourceAddressTranslation.pool = $SourceAddressTranslationPool
      }
    }
    $JSONBody.sourceAddressTranslation = $SourceAddressTranslation

    #Build array of profile items
    $ProfileItems = @()
    ForEach ($ProfileName in $ProfileNames)
    {
      $ProfileItems += @{
        kind = 'tm:ltm:virtual:profiles:profilesstate'
        name = $ProfileName
      }
    }
    $JSONBody.profiles = $ProfileItems

    $JSONBody = $JSONBody | ConvertTo-Json

    if ($pscmdlet.ShouldProcess($F5Session.Name, "Creating virtualserver $Name"))
    {
      Invoke-F5RestMethod -Method POST -Uri "$URI" `
      -F5Session $F5Session `
      -Body $JSONBody `
      -ContentType 'application/json' `
      -ErrorMessage "Failed to create the $($newitem.FullPath) virtual server."
    }
  }
}