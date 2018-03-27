Function Set-VirtualServer {
    <#
        .SYNOPSIS
            Create or update VirtualServer(s)
        .DESCRIPTION
            Can create new or update existing VirtualServer(s).
            If a custom PS object is used, this function uses a defined list of known properties to correct any case discrepancies in property names.
            Not all properties of a virtual server object have been explicitly defined here. However, it is possible to retrieve an existing Virtual Server object from an LTM device, add the required member(s) to it, and pass it to this function and have those properties be updated.
        .PARAMETER InputObject
            The content of the VirtualServer.
        .PARAMETER Application
            The iApp of the VirtualServer.
        .PARAMETER Partition
            The partition on the F5 to put the VirtualServer on.
        .PARAMETER PassThru
            Output the modified VirtualServer to the pipeline.
        .EXAMPLE
            # Creates or updates a VirtualServer.  Note that parameters that are Mandatory for New-VirtualServer must be specified for VirtualServers that do not yet exist.

            Set-VirtualServer -Name 'test.northwindtraders.com' -Description 'Northwind Traders example' -DefaultPool 'test.northwindtraders.com_blue' -Source 0.0.0.0/0 -DestinationIP 192.168.15.98 -DestinationPort 30785 -ipProtocol tcp

        .EXAMPLE
            # Sets the destination port of an existing VirtualServer.

            Set-VirtualServer -Name 'test.northwindtraders.com' -DestinationPort 82

        .EXAMPLE
            # Toggles the pool of an existing VirtualServer via the pipeline and returns the resulting VirtualServer with -PassThru.

            $vs = Get-VirtualServer -Name 'test.northwindtraders.com'
            $vs.pool = if ($vs.pool -eq 'test.northwindtraders.com_blue') { 'test.northwindtraders.com_green' } else { 'test.northwindtraders.com_blue' }
            $vs | Set-VirtualServer -PassThru

        .EXAMPLE
            #Add server, client, and persistence profiles to a virtual server and set the failback persistence profile

            #Define the server and client profiles to apply
            $Profiles = @('http','serverssl','clientssl')
            $ProfileItems = @()
            ForEach ($Profile in $Profiles){
                $ProfileItems += @{
                    kind = 'tm:ltm:virtual:profiles:profilesstate'
                    name = $Profile
                }
            }
            #Add the profiles member to the virtual server object
            $vs | Add-Member -Name 'profiles' -Value $ProfileItems -MemberType NoteProperty


            #Define the persistence profiles to apply
            $PersistenceProfiles = @('hash','cookie')
            $PersistItems = @()
            ForEach ($PersistenceProfile in $PersistenceProfiles){
                $PersistItems += @{
                    name = $PersistenceProfile
                }
            }

            #Add the profiles member to the virtual server object
            $vs | Add-Member -Name 'persist' -Value $PersistItems -MemberType NoteProperty


            #Add the fallbackPersistence member to the virtual server object
            $vs | Add-Member 'fallbackPersistence' -Value 'source_addr'

            #Set the virtual server by passing the modified local object to the LTM
            $vs | Set-VirtualServer

    #>
    [cmdletbinding(ConfirmImpact='Medium',SupportsShouldProcess,DefaultParameterSetName="Default")]
    param (
        $F5Session=$Script:F5Session
        ,
        [Parameter(Mandatory,ParameterSetName='InputObject',ValueFromPipeline)]
        [Alias("VirtualServer")]
        [PSObject[]]$InputObject
        ,
        #region Immutable fullPath component params

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        $Name
        ,
        [Alias('iApp')]
        [Parameter(ValueFromPipelineByPropertyName)]
        $Application=''
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        $Partition='Common'
        ,
        #endregion

        # region New-VirtualServer equivalents

        # region New-VirtualServer equivalents - optional 1-to-1 ValueFromPipelineByPropertyName

        [Parameter(ValueFromPipelineByPropertyName)]
        $Kind='tm:ltm:virtual:virtualstate'
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        $Description=$null
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        $Source='0.0.0.0/0'
        ,
        [Alias('Pool')]
        [Parameter(ValueFromPipelineByPropertyName)]
        $DefaultPool=$null
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        $Mask='255.255.255.255'
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        $ConnectionLimit='0'
        ,
        #endregion

        #region New-VirtualServer equivalents - transformation required

        [PoshLTM.F5Address]$DestinationIP
        ,
        $DestinationPort
        ,
        [Parameter(Mandatory,ParameterSetName='VlanEnabled')]
        [string[]]$VlanEnabled
        ,
        [Parameter(Mandatory,ParameterSetName='VlanDisabled')]
        [string[]]$VlanDisabled
        ,
        [Parameter()]
        [string[]]$ProfileNames=$null
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('tcp','udp','sctp')]
        $ipProtocol=$null
        ,
        #endregion

        #endregion

        [switch]$PassThru
    )

    begin {
        Test-F5Session -F5Session ($F5Session)

        Write-Verbose "NB: Virtual server names are case-specific."

        $knownproperties = @{
            F5Session='F5Session'
            DefaultPool='pool'
            name='name'
            partition='partition'
            kind='kind'
            description='description'
            destination='destination'
            source='source'
            pool='pool'
            ipProtocol='ipProtocol'
            mask='mask'
            connectionLimit='connectionLimit'
        }
    }

    process {
        if ($InputObject -and (
                ($Name -and $Name -cne $InputObject.name) -or
                ($Partition -and $Partition -cne $InputObject.partition) -or
                ($Application -and $Application -cne $InputObject.application)
            )
        ) {
            throw 'Set-VirtualServer does not support moving or renaming at this time.  Use New-VirtualServer and Remove-VirtualServer.'
        }

        $NewProperties = @{} # A hash table to facilitate splatting of New-VirtualServer params
        $ChgProperties = @{} # A hash table of PSBoundParameters to override InputObject properties

        # Build out both hashtables based on $PSBoundParameters
        foreach ($key in $PSBoundParameters.Keys) {
            switch ($key) {
                'DefaultPool' {
                    $NewProperties[$key] = $PSBoundParameters[$key]
                    $ChgProperties[$knownproperties[$key]] = $PSBoundParameters[$key]
                }
                { @('DestinationIP','DestinationPort','F5Session') -contains $key } {
                    $NewProperties[$key] = $PSBoundParameters[$key]
                }
                'ProfileNames' {
                    $NewProperties[$key] = $PSBoundParameters[$key]
                    $ProfileItems = @()
                    ForEach ($ProfileName in $ProfileNames) {
                        $ProfileItems += @{
                            kind = 'tm:ltm:virtual:profiles:profilesstate'
                            name = $ProfileName
                        }
                    }
                    $ChgProperties['profiles'] = $ProfileItems
                }
                'InputObject' {} # Ignore
                'PassThru' {} # Ignore
                { @('VlanEnabled','VlanDisabled') -contains $_ } {
                    $ChgProperties['vlans'] = $NewProperties[$key] = $PSBoundParameters[$key]
                    $ChgProperties[$key] = $true
                }
                default {
                    if ($knownproperties.ContainsKey($key)) {
                        $NewProperties[$key] = $ChgProperties[$knownproperties[$key]] = $PSBoundParameters[$key]
                    }
                }
            }
        }

        # ipProtocol and other Mandatory New-VirtualServer params are set either via ValueFromPipelineByPropertyName or explicitly below (DestinationIP+DestinationPort)
        # New-VirtualServer may throw an error if InputObject excludes them. but they are not all Mandatory to set existing VirtualServers.
        # pool, profiles, and vlans are not Mandatory New-VirtualServer params, so in the absensce of an override they will be applied on the subsequent REST/PUT Update

        $ExistingVirtualServer = Get-VirtualServer -F5Session $F5Session -Name $Name -Application $Application -Partition $Partition -ErrorAction SilentlyContinue

        # Set New DestinationIP/DestinationPort based on $InputObject or existing VirtualServer if necessary and available
        if (-not $NewProperties.ContainsKey('DestinationIP')) {
            $destination = if ($InputObject -and $InputObject.destination) {
                $InputObject.destination
            } elseif ($null -ne $ExistingVirtualServer) {
                $ExistingVirtualServer.destination
            }
            if ($destination) { $NewProperties['DestinationIP'] = ($destination -split ':')[0] }
        }
        if (-not $NewProperties.ContainsKey('DestinationPort')) {
            $destination = if ($InputObject -and $InputObject.destination) {
                $InputObject.destination
            } elseif ($null -eq $ExistingVirtualServer) {
                $ExistingVirtualServer.destination
            }
            if ($destination) { $NewProperties['DestinationPort'] = ($destination -split ':')[1] }
        }
        # Set changed destination if either or both components are overridden via PSBoundParameters
        if ($PSBoundParameters.ContainsKey('DestinationIP') -or $PSBoundParameters.ContainsKey('DestinationPort')) {
            $ChgProperties['destination'] = ('{0}:{1}' -f $NewProperties['DestinationIP'],$NewProperties['DestinationPort'])
        }

        if ($null -eq $ExistingVirtualServer) {
            Write-Verbose -Message 'Creating new VirtualServer...'
            $null = New-VirtualServer @NewProperties
        }
        # This performs the magic necessary for ChgProperties to override $InputObject properties
        $NewObject = Join-Object -Left $InputObject -Right ([pscustomobject]$ChgProperties) -Join FULL -WarningAction SilentlyContinue
        if ($null -ne $NewObject -and $pscmdlet.ShouldProcess($F5Session.Name, "Setting VirtualServer $Name")) {
            Write-Verbose -Message 'Setting VirtualServer details...'

            $URI = $F5Session.BaseURL + 'virtual/{0}' -f (Get-ItemPath -Name $Name -Application $Application -Partition $Partition)
            $JSONBody = $NewObject | ConvertTo-Json -Compress

            #region case-sensitive parameter names

            # If someone inputs their own custom PSObject with properties with unexpected case, this will correct the case of known properties.
            # It could arguably be removed.  If not removed, it should be refactored into a shared (Private) function for use by all Set-* functions in the module.
            $knownRegex = '(?<=")({0})(?=":)' -f ($knownproperties.Keys -join '|')
            # Use of regex.Replace with a callback is more efficient than multiple, separate replacements
            $JsonBody = [regex]::Replace($JSONBody,$knownRegex,{param($match) $knownproperties[$match.Value] }, [Text.RegularExpressions.RegexOptions]::IgnoreCase)

            #endregion

            $null = Invoke-F5RestMethod -Method PATCH -URI "$URI" -F5Session $F5Session -Body $JSONBody -ContentType 'application/json'
        }
        if ($PassThru) { Get-VirtualServer -F5Session $F5Session -Name $Name -Application $Application -Partition $Partition }
    }
}
