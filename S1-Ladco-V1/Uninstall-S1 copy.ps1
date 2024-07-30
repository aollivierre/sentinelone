function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Elevate to administrator if not already
if (-not (Test-Admin)) {
    Write-Host "Restarting script with elevated permissions..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Define the path to the uninstall executable and the log file
$uninstallPath = "C:\Program Files\SentinelOne\Sentinel Agent 22.3.5.887\uninstall.exe"
$logPath = "C:\s1\Uninstall-S1.log"

# Define the uninstallation command arguments with logging
$uninstallArgs = "/uninstall /quiet /norestart"

# Function to log messages
function Log-Message {
    param (
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$level] $message"
    Add-Content -Path $logPath -Value $logEntry
}

# Start logging
Log-Message "Starting uninstallation of SentinelOne agent."

try {
    # Execute the uninstallation command using Start-Process
    Start-Process -FilePath $uninstallPath -ArgumentList $uninstallArgs -Wait -NoNewWindow
    Log-Message "Uninstallation command executed: $uninstallPath $uninstallArgs"
}
catch {
    Log-Message "Error during uninstallation: $_" "ERROR"
}

Log-Message "Uninstallation script completed."
