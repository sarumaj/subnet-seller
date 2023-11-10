[string]$ScriptPath = Split-Path $MyInvocation.MyCommand.Definition -Parent
[string]$ModuleName = (Get-ChildItem $ScriptPath | Where-Object {$_.PSIsContainer -and $_.Name -like 'psmod*'} | Select-Object -First 1 -Property Name).Name

[Environment]::GetEnvironmentVariable("PSModulePath") -Split ';' | ForEach-Object { 
    If ( Test-Path "$($_)\${ModuleName}" ) {
        Try {
            Remove-Item "$($_)\${ModuleName}" -Recurse -Force
            Write-Host "Uninstalled at $($_)." -Fore White 
        } Catch [System.UnauthorizedAccessException]{
            Write-Host $_.Exception.Message -fore red -NoNewline
            Write-Host " Installation requires elevated priviliges." -Fore red
        }
    }
}