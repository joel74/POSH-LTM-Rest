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
    $DestinationIP
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
    $Destination = $DestinationIP + ':' + $DestinationPort
    $JSONBody = @{
      kind            = $Kind
      name            = $newitem.Name
      description     = $Description
      partition       = $newitem.Partition
      destination     = $Destination
      source          = $Source
      pool            = $DefaultPool
      ipProtocol      = $ipProtocol
      mask            = $Mask
      connectionLimit = $ConnectionLimit
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

    #Build array of profile items
    #JN: What happens if a non-existent profile is passed in?
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

    Write-Verbose -Message $JSONBody

    if ($pscmdlet.ShouldProcess($F5Session.Name, "Creating virtualserver $Name"))
    {
      Invoke-RestMethodOverride -Method POST -Uri "$URI" `
      -WebSession $F5Session.WebSession `
      -Body $JSONBody `
      -ContentType 'application/json' `
      -ErrorMessage "Failed to create the $($newitem.FullPath) virtual server."
    }
  }
}