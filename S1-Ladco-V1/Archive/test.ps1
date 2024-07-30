# Define the repository URL and destination path
$repoUrl = "https://github.com/aollivierre/modules/archive/refs/heads/main.zip"
$destinationPath = "C:\code\Forticlient\FortiClientEMS-v7-CBA-National-v3\modules"

# Generate a timestamp for the temporary extraction path
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempExtractPath = "$env:TEMP\modules-$timestamp"

# Download the modules from GitHub
Write-Host "Downloading modules from GitHub..."
$zipPath = "$env:TEMP\modules.zip"
Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath

# Extract the downloaded zip file to the temporary extraction path
Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force
Remove-Item -Path $zipPath

# Define the path to the extracted folder and move its contents
$extractedFolder = Join-Path -Path $tempExtractPath -ChildPath "modules-main"

# Ensure the destination path exists
if (-Not (Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath -Force
}

# Copy the contents of the extracted folder to the destination path
Write-Host "Copying extracted modules to $destinationPath"
Get-ChildItem -Path $extractedFolder -Recurse | ForEach-Object {
    $sourcePath = $_.FullName
    $relativePath = $_.FullName.Substring($extractedFolder.Length + 1)
    $destinationItemPath = Join-Path -Path $destinationPath -ChildPath $relativePath

    if ($_.PSIsContainer) {
        if (-Not (Test-Path $destinationItemPath)) {
            New-Item -ItemType Directory -Path $destinationItemPath -Force
            Write-Host "Created directory: $destinationItemPath"
        }
    } else {
        Copy-Item -Path $sourcePath -Destination $destinationItemPath -Force
        Write-Host "Copied file: $sourcePath to $destinationItemPath"
    }
}

# Clean up the temporary extraction folder
Remove-Item -Path $tempExtractPath -Recurse -Force

Write-Host "Modules downloaded and extracted to $destinationPath"
