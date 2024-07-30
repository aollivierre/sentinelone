# Define the path to the log file
$logPath = "C:\s1\Uninstall-S1.log"

# Define the product code for the MSI
$productCode = "{1678BCB0-F13F-4AAF-9B98-12BE15B02793}"

# Define the uninstallation command arguments with logging
$uninstallArgs = "/x $productCode /quiet /norestart /l*v `"$logPath`""

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
    Start-Process -FilePath "msiexec.exe" -ArgumentList $uninstallArgs -Wait -NoNewWindow
    Log-Message "Uninstallation command executed: msiexec.exe $uninstallArgs"
}
catch {
    Log-Message "Error during uninstallation: $_" "ERROR"
}

Log-Message "Uninstallation script completed."
