[string]$ScriptPath = Split-Path $MyInvocation.MyCommand.Definition -Parent
[string]$ModuleName = (Get-ChildItem $ScriptPath | Where-Object {$_.PSIsContainer -and $_.Name -like 'psmod*'} | Select-Object -First 1 -Property Name).Name
Write-host $ModuleName

[Environment]::GetEnvironmentVariable("PSModulePath") -Split ';' | ForEach-Object { 
    If ( Test-Path $_ ) {
        Try {
            If ( Test-Path "$($_)\${ModuleName}" ) {
                Remove-Item "$($_)\${ModuleName}" -Recurse -Force
            }
            Copy-Item -Path (Resolve-Path "${ScriptPath}\${ModuleName}") -Destination $_ -Recurse -Force -ErrorAction Stop
            Write-Host "Installed at $($_)." -Fore White 
        } Catch [System.UnauthorizedAccessException]{
            Write-Host $_.Exception.Message -fore red -NoNewline
            Write-Host " Installation requires elevated priviliges." -Fore red
        }
    }
}