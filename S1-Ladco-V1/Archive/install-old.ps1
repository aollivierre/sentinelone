#Unique Tracking ID: 38a3388c-26f3-4290-a4f0-fc32b3c23723, Timestamp: 2024-03-05 11:11:26
# Start the process, wait for it to complete, and optionally hide the window

$d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden
