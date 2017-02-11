Function Set-VirtualServer {
    <#
        .SYNOPSIS
            Create or update VirtualServer(s)
        .DESCRIPTION
            Can create new or update existing VirtualServer(s).
        .PARAMETER InputObject
            The content of the VirtualServer.
        .PARAMETER Application
            The iApp of the VirtualServer.
        .PARAMETER Partition
            The partition on the F5 to put the VirtualServer on.
        .PARAMETER PassThru
            Output the modified VirtualServer to the pipeline.
        .EXAMPLE
            Set-VirtualServer -name 'NameThatMakesSense' -InputObject $VirtualServerPSObject
    #>
    [cmdletbinding(ConfirmImpact='Medium',SupportsShouldProcess,DefaultParameterSetName="Default")]
    param (
        $F5Session=$Script:F5Session,

        [Parameter(Mandatory,ParameterSetName='InputObject',ValueFromPipeline)]
        [Alias("VirtualServer")]
        [PSObject[]]$InputObject,

        #region Immutable fullPath component params

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        $Name,

        [Alias('iApp')]
        [Parameter(ValueFromPipelineByPropertyName)]
        $Application='',

        [Parameter(ValueFromPipelineByPropertyName)]
        $Partition='Common',

        #endregion

        # region New-VirtualServer equivalents
        
        # region New-VirtualServer equivalents - optional 1-to-1 ValueFromPipelineByPropertyName

        [Parameter(ValueFromPipelineByPropertyName)]
        $Kind='tm:ltm:virtual:virtualstate',

        [Parameter(ValueFromPipelineByPropertyName)]
        $Description=$null,

        [Parameter(ValueFromPipelineByPropertyName)]
        $Source='0.0.0.0/0',

        [Alias('Pool')]
        [Parameter(ValueFromPipelineByPropertyName)]
        $DefaultPool=$null,

        [Parameter(ValueFromPipelineByPropertyName)]
        $Mask='255.255.255.255',

        [Parameter(ValueFromPipelineByPropertyName)]
        $ConnectionLimit='0',        

        #endregion

        #region New-VirtualServer equivalents - transformation required

        [Parameter(ParameterSetName='InputObject')]
        [Parameter(Mandatory,ParameterSetName='Default')]
        [Parameter(Mandatory,ParameterSetName='VlanDisabled')]
        [Parameter(Mandatory,ParameterSetName='VlanEnabled')]
        $DestinationIP,

        [Parameter(ParameterSetName='InputObject')]
        [Parameter(Mandatory,ParameterSetName='Default')]
        [Parameter(Mandatory,ParameterSetName='VlanDisabled')]
        [Parameter(Mandatory,ParameterSetName='VlanEnabled')]
        $DestinationPort,

        [Parameter(Mandatory,ParameterSetName='VlanEnabled')]
        [string[]]$VlanEnabled,

        [Parameter(Mandatory,ParameterSetName='VlanDisabled')]
        [string[]]$VlanDisabled,

        [Parameter]
        [string[]]$ProfileNames=$null,

        [Parameter(ParameterSetName='InputObject',ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory,ParameterSetName='Default')]
        [Parameter(Mandatory,ParameterSetName='VlanDisabled')]
        [Parameter(Mandatory,ParameterSetName='VlanEnabled')]
        [ValidateSet('tcp','udp','sctp')]
        $ipProtocol=$null,

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
                    $NewProperties[$key] = $PSBoundParamters[$key]
                    $ProfileItems = @()
                    ForEach ($ProfileName in $ProfileNames) {
                        $ProfileItems += @{
                            kind = 'tm:ltm:virtual:profiles:profilesstate'
                            name = $ProfileName
                        }
                    }
                    $ChgProperties[$knownproperties[$key]] = $ProfileItems
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
        
        # ipProtocol is required by New-VirtualServer, so pull it from $InputObject if necessary
        if (-not ($NewProperties.ContainsKey('ipProtocol')) -and $InputObject.ipProtocol) {
            $NewProperties['ipProtocol'] = $InputObject.ipProtocol
        }

        # pool, profiles, and vlans are not required by New-VirtualServer, so in the absensce of an override they will be applied on the subsequent REST/PUT Update
        
        # Applies DestinationIP and/or DestinationPort overrides if supplied
        if ($NewProperties.ContainsKey('DestinationIP') -or $NewProperties.ContainsKey('DestinationPort')) {
            $destIP = if ($NewProperties.ContainsKey('DestinationIP')) { 
                $NewProperties['DestinationIP'] 
            } elseif ($InputObject.destination) {
                ($InputObject.destination -split ':')[0]
            }
            $destPort = if ($NewProperties.ContainsKey('DestinationPort')) { 
                $NewProperties['DestinationPort'] 
            } elseif ($InputObject.destination) {
                ($InputObject.destination -split ':')[1]
            }
            $ChgProperties['destination'] = ('{0}:{1}' -f $destIP,$destPort)
        }

        if (-not (Test-VirtualServer -F5Session $F5Session -Name $Name -Application $Application -Partition $Partition)) {
            Write-Verbose -Message 'Creating new VirtualServer...'
            New-VirtualServer @NewProperties
        }
        if ($pscmdlet.ShouldProcess($F5Session.Name, "Setting VirtualServer $Name")) {
            Write-Verbose -Message 'Setting VirtualServer details...'

            # This performs the magic necessary for ChgProperties to override $InputObject properties
            $NewObject = Join-Object -Left $InputObject -Right ([pscustomobject]$ChgProperties)
                
            $URI = $F5Session.BaseURL + 'virtual/{0}' -f (Get-ItemPath -Name $Name -Application $Application -Partition $Partition) 
            $JSONBody = $NewObject | ConvertTo-Json -Compress

            #region case-sensitive parameter names

            # If someone inputs their own custom PSObject with properties with unexpected case, this will correct the case of known properties.
            # It could arguably be removed.  If not removed, it should be refactored into a shared (Private) function for use by all Set-* functions in the module.
            $knownRegex = '(?<=")({0})(?=":)' -f ($knownproperties.Keys -join '|')
            # Use of regex.Replace with a callback is more efficient than multiple, separate replacements
            $JsonBody = [regex]::Replace($JSONBody,$knownRegex,{param($match) $knownproperties[$match.Value] }, [Text.RegularExpressions.RegexOptions]::IgnoreCase)

            #endregion

            $result = Invoke-RestMethodOverride -Method PUT -URI "$URI" -WebSession $F5Session.WebSession -Body $JSONBody -ContentType 'application/json'
        }
        if ($PassThru) { Get-VirtualServer -F5Session $F5Session -Name $Name -Application $Application -Partition $Partition }
    }
}