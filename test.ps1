Param(
    [switch] $local = $false
)

[string]$ScriptPath = Split-Path $MyInvocation.MyCommand.Definition -Parent
[string]$ModuleName = (Get-ChildItem $ScriptPath | Where-Object { $_.PSIsContainer -and $_.Name -like 'psmod*' } | Select-Object -First 1 -Property Name).Name

Get-Module | Where-Object { $_.Name -eq $ModuleName } | Remove-Module
If ( $local.ToBool() ) {
    Import-Module "${ScriptPath}\${ModuleName}\${ModuleName}.psd1" -Verbose
}
else { 
    Import-Module $ModuleName 
}
(Get-Module -Name $ModuleName).ExportedCommands

$mysub = New-Subnet '192.168.0.0' 27 1 32
Write-Host ($mysub | Out-String)
Write-Host ($mysub.list() | Out-String)
("`@startyaml`n" + $mysub.toYAML() + "`n`@endyaml") | Out-File -FilePath (Join-Path $ScriptPath 'plantuml' '#0 init 192.168.0.0 from 29 to 32.puml')
#("`@startjson`n" + $mysub.toJSON() + "`n`@endjson") | Out-File -FilePath (Join-Path $ScriptPath 'plantuml' '#0 init 192.168.0.0 from 29 to 32 (json).puml')
#("`@startuml`n" + $mysub.toDOT() + "`n`@enduml") | Out-File -FilePath (Join-Path $ScriptPath 'plantuml' '#0 init 192.168.0.0 from 29 to 32 (dot).puml')

$mysub.sell('192.168.0.0', 30, "sold-out on $(Get-Date)")
("`@startyaml`n" + $mysub.toYAML() + "`n`@endyaml") | Out-File -FilePath (Join-Path $ScriptPath 'plantuml' '#1 sold 192.168.0.0_30.puml')
$mysub.sell('192.168.0.8', 31, "sold-out on $(Get-Date)")
("`@startyaml`n" + $mysub.toYAML() + "`n`@endyaml") | Out-File -FilePath (Join-Path $ScriptPath 'plantuml' '#2 sold 192.168.0.8_31.puml')
$mysub.repurchase('192.168.0.8', 31, "repurchased on $(Get-Date)")
("`@startyaml`n" + $mysub.toYAML() + "`n`@endyaml") | Out-File -FilePath (Join-Path $ScriptPath 'plantuml' '#3 repurchased 192.168.0.8_31.puml')
$mysub.print()
Write-Host "Search: $($mysub.search(30) | Out-String)"
Write-Host "Search all: $($mysub.find_all(30) | Out-String)"
If ($null -ne ( Get-Command java -ErrorAction SilentlyContinue )) {
    java -jar (Join-Path $ScriptPath 'plantuml' 'plantuml.jar') -o "$(Join-Path $ScriptPath 'plantuml' 'output')" -tsvg "$(Join-Path $ScriptPath 'plantuml' '*.puml')"
    java -jar (Join-Path $ScriptPath 'plantuml' 'plantuml.jar') -o "$(Join-Path $ScriptPath 'plantuml' 'output')" -tpng "$(Join-Path $ScriptPath 'plantuml' '*.puml')"
}
Remove-Item -Path (Join-Path $ScriptPath 'plantuml' '*.puml')
Invoke-Item (Join-Path $ScriptPath 'plantuml' 'output')
