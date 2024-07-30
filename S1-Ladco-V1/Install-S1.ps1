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

# Define the path to the MSI and the token file
$msiPath = "C:\s1\S1.msi"
$tokenPath = "C:\s1\t.txt"
$logPath = "C:\s1\Install-S1.log"

# Read the token from the file
$token = Get-Content -Path $tokenPath -Raw

# Define the installation command arguments with logging
$installArgs = "/i `"$msiPath`" SITE_TOKEN=$token /quiet /norestart /l*v `"$logPath`""

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
Log-Message "Starting installation of SentinelOne agent."

try {
    # Execute the installation command using Start-Process
    Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -NoNewWindow
    Log-Message "Installation command executed: msiexec.exe $installArgs"
}
catch {
    Log-Message "Error during installation: $_" "ERROR"
}

Log-Message "Installation script completed."
