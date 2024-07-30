

# Set batch file to run in Safe Mode
$batchFilePath = "C:\temp\saferemove.bat"
Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name '*!test' -Value $batchFilePath

# Configure automatic login
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" -Name "fcremove" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value "1"
Set-ItemProperty -Path "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName" -Value "fcremove"
Set-ItemProperty -Path "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -Value "fcremove"
Set-ItemProperty -Path "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultDomainName" -Value $env:COMPUTERNAME

# Reboot into Safe Mode
bcdedit /set {default} safeboot network
shutdown /r /f /t 00

# Create saferemove.bat
$saferemoveContent = @"
cd c:\temp
fcremove.exe
timeout /t 180 /nobreak
bcdedit /deletevalue {default} safeboot
shutdown /r /f /t 00
"@
Set-Content -Path "C:\temp\saferemove.bat" -Value $saferemoveContent -Force

# Create a script to remove auto-login after rebooting into normal mode
$removeAutologinContent = @"
rem Remove auto login
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultDomainName /f
"@
Set-Content -Path "C:\temp\remove_autologin.bat" -Value $removeAutologinContent -Force

# Add the script to RunOnce to remove auto-login settings after rebooting into normal mode
Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name 'RemoveAutoLogin' -Value "C:\temp\remove_autologin.bat"
