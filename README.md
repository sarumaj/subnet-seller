# subnet_seller

Algorithm coded for .NET or PowerShell applications/scripts to manage a network subnet (sell/restore/resell subnets) from a supernet.

## Usage
```
$mySub = New-Subnet '192.168.0.0' 16 6 26
Write-Host ($mySub | Out-String)
>> 
>> 
>> 
>> RecursionLevel   : 0
>> IPAddress        : 192.168.0.0
>> MaskBits         : 16
>> NetworkAddress   : 192.168.0.0
>> BroadcastAddress : 192.168.255.255
>> SubnetMask       : 255.255.0.0
>> Range            : 192.168.0.0 ~ 192.168.255.255
>> Available        : True
>> HostAddresses    : 65534
>> MaskOffset       : 6
>> MaskLimit        : 26
>> 
>> 
>> 
Write-Host ($mySub.list() | Out-String)
>> 
>> 
>>
>> Network      : 192.168.0.0/16
>> Available    : True
>> Range        : 192.168.0.0 ~ 192.168.255.255
>> HostAddresses : 65534
>> Subnets      : {@{Network=192.168.0.0/23; Available=True; Range=192.168.0.0 ~ 192.168.1.255; HostAddresses=510; Subnets=System.Object[]}, @{Network=192.168.2.0/23; 
>> Available=True; Range=192.168.2.0 ~ 192.168.3.255; HostAddresses=510; Subnets=System.Object[]}...}
>> 
>> 
>> 
$mySub.sell('192.168.2.128', 25, "sold-out on $(Get-Date)")
$mySub.sell('192.168.3.0', 25, "sold-out on $(Get-Date)")
$mySub.sell('192.168.3.128', 26, "sold-out on $(Get-Date)")
$mySub.repurchase('192.168.2.128', 25, "repurchased on $(Get-Date)")
$mySub.repurchase('192.168.3.128', 26, "repurchased on $(Get-Date)")
$mySub.print()
>> 
>> 
>> 
>> 192.168.0.0/16(Available:False)
>> --------------192.168.0.0/23(Available:True)
>> ----------------192.168.0.0/24(Available:True)
>> ------------------192.168.0.0/25(Available:True)
>> --------------------192.168.0.0/26(Available:True)
>> --------------------192.168.0.64/26(Available:True)
>> ------------------192.168.0.128/25(Available:True)
>> --------------------192.168.0.128/26(Available:True)
>> --------------------192.168.0.192/26(Available:True)
>> ----------------192.168.1.0/24(Available:True)
>> ------------------192.168.1.0/25(Available:True)
>> --------------------192.168.1.0/26(Available:True)
>> --------------------192.168.1.64/26(Available:True)
>> ------------------192.168.1.128/25(Available:True)
>> --------------------192.168.1.128/26(Available:True)
>> --------------------192.168.1.192/26(Available:True)
>> --------------192.168.2.0/23(Available:False)
>> ----------------192.168.2.0/24(Available:True)
>> ------------------192.168.2.0/25(Available:True)
>> --------------------192.168.2.0/26(Available:True)
>> --------------------192.168.2.64/26(Available:True)
>> ------------------192.168.2.128/25(Available:True,Comment:repurchased on 04/25/2022 10:14:45)
>> --------------------192.168.2.128/26(Available:True)
>> --------------------192.168.2.192/26(Available:True)
>> ----------------192.168.3.0/24(Available:False)
>> ------------------192.168.3.0/25(Available:False,Comment:sold-out on 04/25/2022 10:14:45)
>> ------------------192.168.3.128/25(Available:True)
>> --------------------192.168.3.128/26(Available:True,Comment:repurchased on 04/25/2022 10:14:45)
>> --------------------192.168.3.192/26(Available:True)
>> ...
```

## Snapshots

### #1 192.168.0.0/29 split down from /29 to /32
![test](plantuml/output/%230%20init%20192.168.0.0%20from%2029%20to%2032.png)

### #2 Sold 192.168.0.0/30
![test](plantuml/output/%231%20sold%20192.168.0.0_30.png)

### #3 Sold 192.168.0.8/31
![test](plantuml/output/%232%20sold%20192.168.0.8_31.png)

### #4 Repurchased 192.168.0.8/31
![test](plantuml/output/%233%20repurchased%20192.168.0.8_31.png)
