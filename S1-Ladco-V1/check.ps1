<#
.SYNOPSIS
Checks for the installation of FortiClient versions older than 7.4.

.DESCRIPTION
This script searches the system's uninstallation registry keys for FortiClient installations. 
It checks if any installed version is older than 7.4 and provides feedback based on this condition.

.NOTES
Version:        1.0
Author:         Abdullah Ollivierre
Creation Date:  2024-03-05
#>


# Define constants for registry paths and the version to exclude
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
$targetSoftwareName = "*FortiClient*"
$excludedVersion = New-Object Version "7.4.0.1658"

# Function to check for FortiClientVPN installation and version
function FortiClientVPNInstallation {
    param (
        [string[]]$RegistryPaths,
        [string]$SoftwareName,
        [version]$ExcludedVersion
    )

    foreach ($path in $RegistryPaths) {
        $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue

        foreach ($item in $items) {
            $app = Get-ItemProperty -Path $item.PsPath -ErrorAction SilentlyContinue
            if ($app.DisplayName -like "*$SoftwareName*") {
                $installedVersion = New-Object Version $app.DisplayVersion
                if ($installedVersion -lt $ExcludedVersion) {
                    return @{
                        IsInstalled = $true
                        Version = $app.DisplayVersion
                        ProductCode = $app.PSChildName
                    }
                }
            }
        }
    }

    return @{IsInstalled = $false}
}

# Main script execution block
$installationCheck = FortiClientVPNInstallation -RegistryPaths $registryPaths -SoftwareName $targetSoftwareName -ExcludedVersion $excludedVersion

if ($installationCheck.IsInstalled) {
    Write-Output "FortiClientVPN version $($installationCheck.Version) is installed and is older than $excludedVersion."
    exit 0
} else {
    # Write-Output "FortiClientVPN version $excludedVersion or newer is installed, or FortiClientVPN is not installed."
    exit 1
}
