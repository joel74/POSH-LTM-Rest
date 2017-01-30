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
        .PARAMETER Force
            Overwrite the VirtualServer already present on F5.
        .PARAMETER PassThru
            Output the modified VirtualServer to the pipeline.
        .EXAMPLE
            Set-VirtualServer -name 'NameThatMakesSense' -InputObject $VirtualServerPSObject
    #>
    [cmdletbinding(SupportsShouldProcess = $True)]
    param (
        $F5Session = $Script:F5Session,

        [Parameter(Mandatory=$true,ParameterSetName='InputObject',ValueFromPipeline=$true)]
        [Alias("VirtualServer")]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        $Name,

        [Alias('iApp')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        $Application='',

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        $Partition = 'Common',

        [switch]$Force,
        [switch]$PassThru
    )
    
    begin {
        Test-F5Session -F5Session ($F5Session)

        Write-Verbose "NB: Virtual server names are case-specific."
    }
    
    process {
        $VirtualServer = Get-VirtualServer -F5Session $F5Session -Name $Name -Application $Application -Partition $Partition -ErrorAction SilentlyContinue
        if (
            ($Name -and $Name -cne $InputObject.name) -or
            ($Partition -and $Partition -cne $InputObject.partition) -or
            ($Application -and $Application -cne $InputObject.application)
        ) {
            throw 'Set-VirtualServer does not support moving or renaming at this time.  Use New-VirtualServer and Remove-VirtualServer.'
        }
        if ($null -eq $VirtualServer) {
            Write-Verbose -Message 'Creating new VirtualServer...'

            $DestinationIp,$DestinationPort = $InputObject.destination -split ':'
            $VirtualServer = New-VirtualServer -F5Session $F5Session -Name $Name -Application $Application -Partition $Partition -WhatIf:$WhatIf
                -Kind $InputObject.kind 
                -Description $InputObject.description
                -DestinationIP $DestinationIp
                -DestinationPort $DestinationPort
                -Source $InputObject.source
                -DefaultPool $InputObject.pool
                -ipProtocol $InputObject.ipProtocol
                -Mask $InputObject.Mask
                -ConnectionLimit $InputObject.connectionLimit
        }
        $URI = $F5session.GetLink($VirtualServer.selfLink)
        if ($Force -or (Compare-Object -ReferenceObject $InputObject -DifferenceObject $VirtualServer)) {
            Write-Verbose -Message 'Updating existing VirtualServer...'
            if ($pscmdlet.ShouldProcess($F5Session.Name, "Setting VirtualServer $Name")) {
                $JSONBody = $InputObject | ConvertTo-Json -Compress

                # region case-sensitive parameter names

                # If someone inputs their own custom PSObject with properties with unexpected case, this will correct the case of known properties.
                # It could arguably be removed.  If not removed, it should be refactored into a shared (Private) function for use by all Set-* functions in the module.
                $knownproperties = @{
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
                $knownRegex = '(?<=")({0})(?=":)' -f ($knownproperties.Keys -join '|')
                $JsonBody = [regex]::Replace($JSONBody,$knownRegex,{param($match) $knownproperties[$match.Value] }, [Text.RegularExpressions.RegexOptions]::IgnoreCase)

                #endregion

                $result = Invoke-RestMethodOverride -Method PUT -URI "$URI" -WebSession $F5Session.WebSession -Body $JSONBody -ContentType 'application/json'
                if ($PassThru) { $result }
            }
        } else {
            Write-Warning -Message 'VirtualServer on server is different from current version, use -Force to overwrite current VirtualServer.'
        }
    }
}