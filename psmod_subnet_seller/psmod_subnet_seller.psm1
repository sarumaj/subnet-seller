enum Propagation {
    BottomUp = 1
    TopDown = 2
}

class Subnet {
    [ipaddress]       $IPAddress
    [int]             $MaskBits
    [ipaddress]       $NetworkAddress 
    [ipaddress]       $BroadcastAddress
    [ipaddress]       $SubnetMask
    [string]          $Range 
    [bool]            $Available
    [int]             $HostAddresses
    [int]             $MaskOffset
    [int]             $MaskLimit
    [int]             $RecursionLevel = 0
    hidden [Subnet[]] $_nodes = [Subnet[]]::new(2)
    hidden [Subnet]   $_head
    hidden [string]   $_comment

    Subnet(
        [string] $Address,
        [int] $Mask,
        [int] $MaskOffset,
        [int] $MaskLimit,
        [Subnet] $Parent
    ) {
        $this.MaskOffset = $MaskOffset
        $this.MaskLimit = $MaskLimit
        $this.Available = $True
        $this._head = $Parent

        $IPAddr = [ipaddress]::Parse($Address)
        $MaskAddr = [ipaddress]::Parse(
            (
                [Subnet]::dec2ip(
                    (
                        [convert]::ToInt64(
                            ("1" * $Mask + "0" * (32 - $Mask)),
                            2
                        )
                    )
                )
            )
        )
        $NetworkAddr = [ipaddress]($MaskAddr.address -band $IPAddr.address)
        $BroadcastAddr = [ipaddress](
            (
                [ipaddress]::parse("255.255.255.255").address -bxor $MaskAddr.address -bor $NetworkAddr.address
            )
        )
        $HostStartAddr = [Subnet]::ip2dec($NetworkAddr.ipaddresstostring) + 1
        $HostEndAddr = [Subnet]::ip2dec($broadcastaddr.ipaddresstostring) - 1
        $HostAddressCount = ($HostEndAddr - $HostStartAddr) + 1

        $this.IPAddress = $IPAddr
        $this.MaskBits = $Mask
        $this.NetworkAddress = $NetworkAddr
        $this.BroadcastAddress = $broadcastaddr
        $this.SubnetMask = $MaskAddr
        $this.Range = "$networkaddr ~ $broadcastaddr"
        $this.HostAddresses = $HostAddressCount

        If ($null -ne $this._head) {
            If ($this._head.Available -eq $False) {
                $this.Available = $False
            }
            $this.RecursionLevel = $this._head.RecursionLevel + 1
        } 
        $this.divide()
    }

    hidden [void] divide() {
        if (
            ($this.MaskBits -lt 32) -and ($this.MaskBits -lt $this.MaskLimit)
        ) {
            $this._nodes[0] = [Subnet]::new( 
                $this.IPAddress.IPAddressToString, 
                (
                    $this.MaskBits + $this.MaskOffset + 1
                ),
                0,
                $this.MaskLimit,
                $this
            )
            $this._nodes[1] = [Subnet]::new( 
                (
                    [Subnet]::dec2ip(
                        [Subnet]::ip2dec(
                            $this._nodes[0].BroadcastAddress.IPAddressToString
                        ) + 1
                    )
                ), 
                (
                    $this.MaskBits + $this.MaskOffset + 1
                ),
                0,
                $this.MaskLimit,
                $this
            )
            for (
                ($i = 0); $i -lt ( ( 2 -shl $this.MaskOffset ) - 2 ); $i++
            ) {
                $this._nodes += [Subnet]::new( 
                    (
                        [Subnet]::dec2ip(
                            [Subnet]::ip2dec(
                                $this._nodes[-1].BroadcastAddress.IPAddressToString
                            ) + 1
                        )
                    ), 
                    (
                        $this.MaskBits + $this.MaskOffset + 1
                    ),
                    0,
                    $this.MaskLimit,
                    $this
                )
            }
        }
    }

    hidden [void] propagate([switch] $Availability, [Propagation]$direction) {
        If (
            ($null -ne $this._head)
        ) {
            If ($direction -band [Propagation]::BottomUp) {
                $this._head.propagate(
                    $Availability, 
                    [Propagation]::BottomUp
                )
            }
        }
        $nodes_to_propagate = (
            $this._nodes | Where-Object { $null -ne $_ }
        )
        If (
            $nodes_to_propagate.Count -gt 0
        ) {
            If ($direction -band [Propagation]::TopDown) {
                $nodes_to_propagate | ForEach-Object {
                    $_.propagate(
                        $Availability, 
                        [Propagation]::TopDown
                    )
                }
            }
            If (
                ($Availability -eq $True) -and (
                    (
                        $this._nodes.Available | ForEach-Object -Begin {
                            $and = 1
                            $and | Out-Null
                        } -Process {
                            $and = $and -band $_
                        } -End {
                            $and
                        }
                    ) -eq 1
                )
            ) {
                $this.Available = $True
            }
            Else {
                $this.Available = $False
            }
        }
        Else {
            $this.Available = $Availability
        }
    }

    hidden [void] refresh() {
        $this._nodes.Available | ForEach-Object -Begin {
            $and = 1
            $and | Out-Null
        } -Process {
            $and = $and -band $_
        } -End {
            $and = [Convert]::ToBoolean($and)
            If ($and) {
                $this.Available = $and
            }
        }
    }

    [void] sell(
        [string] $Address,
        [int]    $Mask,
        [string] $Comment
    ) {
        If (
            ($this.IPAddress.IPAddressToString -eq $Address) -and ($this.MaskBits -eq $Mask)
        ) {
            If ($this.Available -eq $False) {
                Throw "Subnet $($this.NetworkAddress.IPAddressToString +'/'+ $this.Mask.ToString()) was already sold out!!!"
            }
            $this._comment = $Comment
            $this.propagate(
                $False, (
                    [Propagation]::TopDown -bor [Propagation]::BottomUp
                )
            )
        }
        Else {
            $this._nodes | Where-Object {
                $null -ne $_
            } | ForEach-Object {
                $_.sell(
                    $Address, 
                    $Mask,
                    $Comment
                )
            }
        }
        $this.refresh()
    }

    [void] repurchase(
        [string] $Address,
        [int]    $Mask,
        [string] $Comment
    ) {
        If (
            ($this.IPAddress.IPAddressToString -eq $Address) -and ($this.MaskBits -eq $Mask)
        ) {
            If ($this.Available -eq $True) {
                Throw "Subnet $($this.NetworkAddress.IPAddressToString +'/'+ $this.Mask.ToString()) is already available!!!"
            }
            $this._comment = $Comment
            $this.propagate(
                $True, 
                (
                    [Propagation]::TopDown -bor [Propagation]::BottomUp
                )
            )
        }
        Else {
            $this._nodes | Where-Object {
                $null -ne $_
            } | ForEach-Object {
                $_.repurchase(
                    $Address, 
                    $Mask,
                    $Comment
                )
            }
        }
        $this.refresh()
    }

    [Subnet] search([int] $Mask) {
        If (
            ($this.MaskBits -eq $Mask) -and ($this.Available -eq $True)
        ) {
            return $this
        }
        Elseif (
            ($Mask -ge 16) -and ($Mask -le 32)
        ) {
            $results = (
                $this._nodes | Where-Object {
                    $null -ne $_
                } | ForEach-Object {
                    $_.search($Mask)
                }
            )
            return ($results | Select-Object -First 1)
        }
        Else {
            Throw "Invalid mask! (${Mask})"
        }
    }

    [Subnet[]] find_all([int] $Mask) {
        If (
            ($this.MaskBits -eq $Mask)
        ) {
            return $this
        }
        Elseif (
            ($Mask -ge 16) -and ($Mask -le 32)
        ) {
            $results = (
                $this._nodes | Where-Object {
                    $null -ne $_
                } | ForEach-Object {
                    $_.find_all($Mask)
                }
            )
            return $results
        }
        Else {
            Throw "Invalid mask! (${Mask})"
        }
    }

    [PSCustomObject] list() {
        return [PSCustomObject]@{
            Network       = $this.NetworkAddress.IPAddressToString + '/' + $this.MaskBits.ToString()
            Available     = $this.Available
            Range         = $this.Range
            HostAddresses = $this.HostAddresses
            Subnets       = (
                $this._nodes | Where-Object {
                    $null -ne $_
                } | ForEach-Object {
                    $_.list()
                }
            )
        }
    }

    [Subnet[]] getSubnets() {
        return $this._nodes
    }

    [string] print() {
        return $this.print(32)
    }

    [string] print([int] $SizeLimit) {
        IF ( 
            (
                (
                    $this.Available -eq $False
                ) -and (
                    $null -ne $this._comment
                ) -and (
                    (
                        $this._nodes | ForEach-Object -Begin {
                            $available = 1
                            $available | Out-Null
                        } -Process {
                            If ($null -eq $_) {
                                $available = $available -band 0
                            }
                            Else {
                                $available = $available -band $_.Available
                            }
                        } -End {
                            $available 
                        }
                    ) -eq 0
                )
            ) -or (
                (
                    $this.MaskBits -ge $SizeLimit
                ) -and (
                    $this.Available -eq $True
                )
            )
        ) {
            $node_print = @()
        }
        Else {
            $node_print = @(
                $this._nodes | Where-Object {
                    $null -ne $_
                } | ForEach-Object {
                    $_.print($SizeLimit)
                }
            )
        }
        $out = (
            '--' * $this.RecursionLevel + `
                $this.IPAddress.IPAddressToString + '/' + `
                $this.MaskBits.ToString() + '(Available:' + `
                $this.Available.ToString()
        )
        If ([string]::IsNullOrEmpty($this._comment)) {
            $out += ")`n"
        }
        Else {
            $out += ',Comment:' + $this._comment + ")`n"
        }
        If ($this.Available -eq $True) {
            $out = "$([char]27)[92m${out}$([char]27)[0m"
        }
        Else {
            $out = "$([char]27)[91m${out}$([char]27)[0m"
        }
        $out += ($node_print -Join '')
        return $out
    }

    [string] toJSON() {
        If ($this.Available) {
            $network = "<color:white><back:green>$($this.IPAddress.IPAddressToString)/$($this.MaskBits.ToString())</back></color>"
        }
        Else {
            $network = "<color:orange><back:red>$($this.IPAddress.IPAddressToString)/$($this.MaskBits.ToString())</back></color>"
        }
        $out = "`{""Network"":""${network}"","
        $out += """Comment"":""$($this._comment)"","
        $out += """Available"":$($this.Available.ToString().ToLower()),"
        $out += """Subnets"":["
        $out += (
            (
                $this._nodes | Where-Object {
                    $null -ne $_
                } | ForEach-Object {
                    $_.toJSON()
                }
            ) -Join ','
        )
        $out += "]`}"
        return $out
    }

    [string] toDOT() {
        $out = ''
        if ($this.RecursionLevel -eq 0) {
            $out += "digraph g$($this.IPAddress.IPAddressToString -replace '\.', 'e')m$($this.MaskBits.ToString()) `{`n"
        } 
        $out += "    node$($this.IPAddress.IPAddressToString -replace '\.', 'e')m$($this.MaskBits.ToString()) ["
        If ($this.Available) {
            $out += "fillcolor=green, style=""rounded,filled"", "
        }
        Else {
            $out += "fillcolor=red, style=""rounded,filled"", "
        }
        $out += "shape=record, label=""`{ "
        $out += "Network: $($this.IPAddress.IPAddressToString)/$($this.MaskBits.ToString()) | "
        $out += "Comment: $($this._comment) | "
        $out += "Available: $($this.Available.ToString().ToLower()) `}""]`n"
        $out += (
            (
                $this._nodes | Where-Object {
                    $null -ne $_
                } | ForEach-Object {
                    $_.toDOT()
                }
            ) -Join ''
        )
        $out += (
            (
                $this._nodes | Where-Object {
                    $null -ne $_
                } | ForEach-Object -Begin {
                    $rel = ''
                    $rel | Out-Null
                } -Process {
                    $rel += "    node$($this.IPAddress.IPAddressToString -replace '\.', 'e')m$($this.MaskBits.ToString()) -> "
                    $rel += "node$($_.IPAddress.IPAddressToString -replace '\.', 'e')m$($_.MaskBits.ToString())`n"
                } -End {
                    $rel
                }
            ) -Join ''
        )
        if ($this.RecursionLevel -eq 0) {
            $out += "`}"
        } 
        return $out
    }

    [string] toYAML() {
        If ($this.Available) {
            $network = "<color:white><back:green>$($this.IPAddress.IPAddressToString)/$($this.MaskBits.ToString())</back></color>"
        }
        Else {
            $network = "<color:orange><back:red>$($this.IPAddress.IPAddressToString)/$($this.MaskBits.ToString())</back></color>"
        }
        If ($this.RecursionLevel -eq 0) {
            $out = "Network:   ""${network}""`n"
            $out += "Comment:   ""$($this._comment)""`n"
            $out += "Available: $($this.Available.ToString())`n"
        }
        Else {
            $out = "   " * ($this.RecursionLevel + 1) + " - Network:   ""${network}""`n"
            $out += "   " * ($this.RecursionLevel + 2) + "Comment:   ""$($this._comment)""`n"
            $out += "   " * ($this.RecursionLevel + 2) + "Available: $($this.Available.ToString())`n"
        }
        $nodes_to_yaml = (
            $this._nodes | Where-Object {
                $null -ne $_
            } | ForEach-Object {
                $_.toYAML()
            }
        )
        If ($nodes_to_yaml.Count -gt 0) {
            If ($this.RecursionLevel -eq 0) {
                $out += "Subnets:`n"
            }
            Else {
                $out += "   " * ($this.RecursionLevel + 2) + "Subnets:`n"
            }
            $out += ($nodes_to_yaml -Join '')
        }
        return $out
    }

    static [int64] ip2dec ( [string]$ip ) { 
        $octets = $ip.split(".") 
        return [int64](
            [int64]$octets[0] * (256 -shl 16) + `
                [int64]$octets[1] * (256 -shl 8) + `
                [int64]$octets[2] * 256 + `
                [int64]$octets[3]
        ) 
    }
    
    static [string] dec2ip ( [int64]$int ) { 
        return (
            (
                [math]::truncate($int / (256 -shl 16))
            ).tostring() + "." + (
                [math]::truncate(($int % (256 -shl 16)) / (256 -shl 8))
            ).tostring() + "." + (
                [math]::truncate(($int % (256 -shl 8)) / 256)
            ).tostring() + "." + (
                [math]::truncate($int % 256)
            ).tostring() 
        )
    }
}

Function New-Subnet(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidatePattern('^((?:\d{1,3}\.?){4})$')]
    [string] $Address,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateRange(16, 31)]
    [int] $Mask,
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
    [ValidateScript({ ($_ + $Mask -le 31) -and ($_ -ge 0) })]
    [int] $MaskOffset = 0,
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
    [ValidateScript({ ($_ -gt $Mask + $MaskOffset) -and ($_ -le 32) })]
    [int] $MaskLimit = 31,
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
    [Subnet] $Parent = $null
) {
    return [Subnet]::new($Address, $Mask, $MaskOffset , $MaskLimit, $Parent)
}
