$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$scriptRoot\Install-S1.ps1`""