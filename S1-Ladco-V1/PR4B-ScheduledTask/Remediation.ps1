#############################################################################################################
#
#   Tool:           Intune Win32 Deployer
#   Author:         Abdullah Ollivierre
#   Website:        https://github.com/aollivierre
#   Twitter:        https://x.com/ollivierre
#   LinkedIn:       https://www.linkedin.com/in/aollivierre
#
#   Description:    https://github.com/aollivierre
#
#############################################################################################################

<#
    .SYNOPSIS
    Packages any custom app for MEM (Intune) deployment.
    Uploads the packaged into the target Intune tenant.

    .NOTES
    For details on IntuneWin32App go here: https://github.com/aollivierre

#>

#################################################################################################################################
################################################# START VARIABLES ###############################################################
#################################################################################################################################

#First, load secrets and create a credential object:
# Assuming secrets.json is in the same directory as your script
# $secretsPath = Join-Path -Path $PSScriptRoot -ChildPath "secrets.json"

# Load the secrets from the JSON file
# $secrets = Get-Content -Path $secretsPath -Raw | ConvertFrom-Json

# Read configuration from the JSON file
# Assign values from JSON to variables

# Read configuration from the JSON file
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$env:MYMODULE_CONFIG_PATH = $configPath

$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

#  Variables from JSON file
# $tenantId = $secrets.tenantId
# $clientId = $secrets.clientId

# $certPath = Join-Path -Path $PSScriptRoot -ChildPath 'graphcert.pfx'
# $CertPassword = $secrets.CertPassword
# $siteObjectId = $secrets.SiteObjectId
# $documentDriveName = $secrets.DocumentDriveName


function Initialize-Environment {
    param (
        [string]$WindowsModulePath = "EnhancedBoilerPlateAO\2.0.0\EnhancedBoilerPlateAO.psm1",
        [string]$LinuxModulePath = "/usr/src/code/Modules/EnhancedBoilerPlateAO/2.0.0/EnhancedBoilerPlateAO.psm1"
    )

    function Get-Platform {
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            return $PSVersionTable.Platform
        }
        else {
            return [System.Environment]::OSVersion.Platform
        }
    }

    function Setup-GlobalPaths {
        if ($env:DOCKER_ENV -eq $true) {
            $global:scriptBasePath = $env:SCRIPT_BASE_PATH
            $global:modulesBasePath = $env:MODULES_BASE_PATH
        }
        else {
            $global:scriptBasePath = $PSScriptRoot
            $global:modulesBasePath = "$PSScriptRoot\modules"
        }
    }

    function Setup-WindowsEnvironment {
        # Get the base paths from the global variables
        Setup-GlobalPaths

        # Construct the paths dynamically using the base paths
        $global:modulePath = Join-Path -Path $modulesBasePath -ChildPath $WindowsModulePath
        $global:AOscriptDirectory = Join-Path -Path $scriptBasePath -ChildPath "Win32Apps-DropBox"
        $global:directoryPath = Join-Path -Path $scriptBasePath -ChildPath "Win32Apps-DropBox"
        $global:Repo_Path = $scriptBasePath
        $global:Repo_winget = "$Repo_Path\Win32Apps-DropBox"


        # Import the module using the dynamically constructed path
        Import-Module -Name $global:modulePath -Verbose -Force:$true -Global:$true

        # Log the paths to verify
        Write-Output "Module Path: $global:modulePath"
        Write-Output "Repo Path: $global:Repo_Path"
        Write-Output "Repo Winget Path: $global:Repo_winget"
    }

    function Setup-LinuxEnvironment {
        # Get the base paths from the global variables
        Setup-GlobalPaths

        # Import the module using the Linux path
        Import-Module $LinuxModulePath -Verbose

        # Convert paths from Windows to Linux format
        $global:AOscriptDirectory = Convert-WindowsPathToLinuxPath -WindowsPath "C:\Users\Admin-Abdullah\AppData\Local\Intune-Win32-Deployer"
        $global:directoryPath = Convert-WindowsPathToLinuxPath -WindowsPath "C:\Users\Admin-Abdullah\AppData\Local\Intune-Win32-Deployer\Win32Apps-DropBox"
        $global:Repo_Path = Convert-WindowsPathToLinuxPath -WindowsPath "C:\Users\Admin-Abdullah\AppData\Local\Intune-Win32-Deployer"
        $global:Repo_winget = "$global:Repo_Path\Win32Apps-DropBox"
    }

    $platform = Get-Platform
    if ($platform -eq 'Win32NT' -or $platform -eq [System.PlatformID]::Win32NT) {
        Setup-WindowsEnvironment
    }
    elseif ($platform -eq 'Unix' -or $platform -eq [System.PlatformID]::Unix) {
        Setup-LinuxEnvironment
    }
    else {
        throw "Unsupported operating system"
    }
}

# Call the function to initialize the environment
Initialize-Environment


# Example usage of global variables outside the function
Write-Output "Global variables set by Initialize-Environment:"
Write-Output "scriptBasePath: $scriptBasePath"
Write-Output "modulesBasePath: $modulesBasePath"
Write-Output "modulePath: $modulePath"
Write-Output "AOscriptDirectory: $AOscriptDirectory"
Write-Output "directoryPath: $directoryPath"
Write-Output "Repo_Path: $Repo_Path"
Write-Output "Repo_winget: $Repo_winget"

#################################################################################################################################
################################################# END VARIABLES #################################################################
#################################################################################################################################

###############################################################################################################################
############################################### START MODULE LOADING ##########################################################
###############################################################################################################################

<#
.SYNOPSIS
Dot-sources all PowerShell scripts in the 'private' folder relative to the script root.

.DESCRIPTION
This function finds all PowerShell (.ps1) scripts in a 'private' folder located in the script root directory and dot-sources them. It logs the process, including any errors encountered, with optional color coding.

.EXAMPLE
Dot-SourcePrivateScripts

Dot-sources all scripts in the 'private' folder and logs the process.

.NOTES
Ensure the Write-EnhancedLog function is defined before using this function for logging purposes.
#>


Write-Host "Starting to call Get-ModulesFolderPath..."

# Store the outcome in $ModulesFolderPath
try {
  
    # $ModulesFolderPath = Get-ModulesFolderPath -WindowsPath "C:\code\modules" -UnixPath "/usr/src/code/modules"
    $ModulesFolderPath = Get-ModulesFolderPath -WindowsPath "$PsScriptRoot\modules" -UnixPath "$PsScriptRoot/modules"
    Write-host "Modules folder path: $ModulesFolderPath"

}
catch {
    Write-Error $_.Exception.Message
}


Write-Host "Starting to call Import-LatestModulesLocalRepository..."
Import-LatestModulesLocalRepository -ModulesFolderPath $ModulesFolderPath -ScriptPath $PSScriptRoot

###############################################################################################################################
############################################### END MODULE LOADING ############################################################
###############################################################################################################################
try {
    Ensure-LoggingFunctionExists -LoggingFunctionName "Write-EnhancedLog"
    # Continue with the rest of the script here
    # exit
}
catch {
    Write-Host "Critical error: $_" -ForegroundColor Red
    Handle-Error $_.
    exit
}

###############################################################################################################################
###############################################################################################################################
###############################################################################################################################

# Setup logging
Write-EnhancedLog -Message "Script Started" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)

################################################################################################################################
################################################################################################################################
################################################################################################################################

# Execute InstallAndImportModulesPSGallery function
InstallAndImportModulesPSGallery -moduleJsonPath "$PSScriptRoot/modules.json"

################################################################################################################################
################################################ END MODULE CHECKING ###########################################################
################################################################################################################################

    
################################################################################################################################
################################################ END LOGGING ###################################################################
################################################################################################################################

#  Define the variables to be used for the function
#  $PSADTdownloadParams = @{
#      GithubRepository     = "psappdeploytoolkit/psappdeploytoolkit"
#      FilenamePatternMatch = "PSAppDeployToolkit*.zip"
#      ZipExtractionPath    = Join-Path "$PSScriptRoot\private" "PSAppDeployToolkit"
#  }

#  Call the function with the variables
#  Download-PSAppDeployToolkit @PSADTdownloadParams

################################################################################################################################
################################################ END DOWNLOADING PSADT #########################################################
################################################################################################################################


##########################################################################################################################
############################################STARTING THE MAIN FUNCTION LOGIC HERE#########################################
##########################################################################################################################


################################################################################################################################
################################################ START GRAPH CONNECTING ########################################################
################################################################################################################################
# $accessToken = Connect-GraphWithCert -tenantId $tenantId -clientId $clientId -certPath $certPath -certPassword $certPassword

# Log-Params -Params @{accessToken = $accessToken }

# Get-TenantDetails
#################################################################################################################################
################################################# END Connecting to Graph #######################################################
#################################################################################################################################

# #################################################################################################################################
# ################################################# Creating VPN Connection #######################################################
# #################################################################################################################################

# Example usage
# $vpnConnectionName = "MyVPNConnection"
# $vpnServerAddress = "vpn.example.com"
# New-And-ValidateVPNConnection -VPNConnectionName $vpnConnectionName -VPNServerAddress $vpnServerAddress


# #################################################################################################################################
# ################################################# END Creating VPN Connection (uncomment if needed) #############################
# #################################################################################################################################

#################################################################################################################################
################################################# START VPN Export #############################################################
#################################################################################################################################
# Ensure the VPNExport folder exists
# $ExportsFolderPath = Ensure-ExportsFolder -BasePath $PSScriptRoot

# $exportsFolderName = "CustomExports"
# $exportSubFolderName = "CustomVPNLogs"

# $ExportsFolderPath = Ensure-ExportsFolder -BasePath $PSScriptRoot -ExportsFolderName $ExportsFolderName -ExportSubFolderName $ExportSubFolderName

# Write-EnhancedLog -Message "Exports folder path: $ExportsFolderPath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)

# # Log parameters
# Log-Params @{
#     BasePath          = $PSScriptRoot
#     ExportsFolderPath = $ExportsFolderPath
# }

# # Call the function to export VPN connections
# Export-VPNConnectionsToXML -ExportFolder $ExportsFolderPath
# #################################################################################################################################
# ################################################# END VPN Export ###############################################################
# #################################################################################################################################


# try {
#     # Get an access token for the Microsoft Graph API
#     # Set up headers for API requests
#     $headers = @{
#         "Authorization" = "Bearer $($accessToken)"
#         "Content-Type"  = "application/json"
#     }

#     # Get the ID of the SharePoint document drive
#     $documentDriveId = Get-SharePointDocumentDriveId -SiteObjectId $siteObjectId -DocumentDriveName $documentDriveName -Headers $headers

#     Log-Params -Params @{document_drive_id = $documentDriveId }

#     # Get the computer name and detailed info
#     $computerName = $env:COMPUTERNAME
#     $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem | Format-List | Out-String
#     $allScanResults = @()

#     $detectedFolderPath = "VPNLogs"

#     # Generate a report file containing the paths of the files found
#     Write-EnhancedLog -Message "Generating report..."
#     $reportFileName = "ExportVPN_${computerName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
#     $reportFilePath = Join-Path -Path $env:TEMP -ChildPath $reportFileName
#     # $CSVFilePath = "$scriptPath\exports\CSV\$Filename.csv"

#     # Add computer info and scan results to the report file
#     $computerInfo | Set-Content -Path $reportFilePath
#     $allScanResults | Add-Content -Path $reportFilePath

#     # Create the "Infected" folder in SharePoint if it doesn't exist
#     New-SharePointFolder -DocumentDriveId $documentDriveId -ParentFolderPath $detectedFolderPath -FolderName $computerName -Headers $headers

#     $detectedtargetFolderPath = "$detectedFolderPath/$computerName"
#     Upload-FileToSharePoint -DocumentDriveId $documentDriveId -FilePath $reportFilePath -FolderName $detectedtargetFolderPath -Headers $headers
#     # Upload-FileToSharePoint -DocumentDriveId $documentDriveId -FilePath $CSVFilePath -FolderName $detectedtargetFolderPath -Headers $headers

# }
# catch {
#     Write-EnhancedLog -Message "An error occurred: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
# }

# # Stop-Transcript

# # Create a folder in SharePoint named after the computer
# $computerName = $env:COMPUTERNAME
# $parentFolderPath = "VPN"  # Change this to the desired parent folder path in SharePoint
# New-SharePointFolder -DocumentDriveId $documentDriveId -ParentFolderPath $parentFolderPath -FolderName $computerName -Headers $headers

# # Upload the transcript log to the new SharePoint folder
# $targetFolderPath = "$parentFolderPath/$computerName"
# # $LocalFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "Exports"
# $LocalFolderPath = $ExportsFolderPath


# # Get all files in the folder
# $FilesToUpload = Get-ChildItem -Path $LocalFolderPath -File -Recurse

# foreach ($File in $FilesToUpload) {
#     Upload-FileToSharePoint -DocumentDriveId $documentDriveId -FilePath $File.FullName -FolderName $targetFolderPath -Headers $headers
# }





# ################################################################################################################################
# ############### CALLING AS SYSTEM to simulate Intune deployment as SYSTEM (Uncomment for debugging) ############################
# ################################################################################################################################

# Example usage
$privateFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "private"
$PsExec64Path = Join-Path -Path $privateFolderPath -ChildPath "PsExec64.exe"
$ScriptToRunAsSystem = $MyInvocation.MyCommand.Path

Ensure-RunningAsSystem -PsExec64Path $PsExec64Path -ScriptPath $ScriptToRunAsSystem -TargetFolder $privateFolderPath


# ################################################################################################################################
# ################################################ END CALLING AS SYSTEM (Uncomment for debugging) ###############################
# ################################################################################################################################







<#
.SYNOPSIS
    Escrow (Backup) the existing Bitlocker key protectors to Azure AD (Intune)

.DESCRIPTION
    This script will verify the presence of existing recovery keys and have them escrowed (backed up) to Azure AD
    Great for switching away from MBAM on-prem to using Intune and Azure AD for Bitlocker key management

.INPUTS
    None

.NOTES
    Version       : 1.0
    Author        : Michael Mardahl
    Twitter       : @michael_mardahl
    Blogging on   : www.msendpointmgr.com
    Creation Date : 11 January 2021
    Purpose/Change: Initial script
    License       : MIT (Leave author credits)

.EXAMPLE
    Execute script as system or administrator
    .\Invoke-EscrowBitlockerToAAD.ps1

.NOTES
    If there is a policy mismatch, then you might get errors from the built-in cmdlet BackupToAAD-BitLockerKeyProtector.
    So I have wrapped the cmdlet in a try/catch in order to supress the error. This means that you will have to manually verify that the key was actually escrowed.
    Check MSEndpointMgr.com for solutions to get reporting stats on this.

#>

# #region declarations

# $DriveLetter = $env:SystemDrive

# #endregion declarations

# #region functions

# function Test-Bitlocker ($BitlockerDrive) {
#     #Tests the drive for existing Bitlocker keyprotectors
#     try {
#         Get-BitLockerVolume -MountPoint $BitlockerDrive -ErrorAction Stop
#     } catch {
#         # Write-Output "Bitlocker was not found protecting the $BitlockerDrive drive. Terminating script!"
#         exit 0
#     }
# }

# function Get-KeyProtectorId ($BitlockerDrive) {
#     #fetches the key protector ID of the drive
#     $BitLockerVolume = Get-BitLockerVolume -MountPoint $BitlockerDrive
#     $KeyProtector = $BitLockerVolume.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
#     return $KeyProtector.KeyProtectorId
# }

# function Invoke-BitlockerEscrow ($BitlockerDrive,$BitlockerKey) {
#     #Escrow the key into Azure AD


#     Write-host "calling Invoke-BitlockerEscrow"
#     foreach ($Key in $BitlockerKey) {

#         try {
#             BackupToAAD-BitLockerKeyProtector -MountPoint $BitlockerDrive -KeyProtectorId $Key #-ErrorAction SilentlyContinue
#             Write-host "Attempted to escrow key in Azure AD - Please verify manually!"
            
#         } catch {
#             # Write-Error "This should never have happend? Debug me!"
#             exit 1
#         }

#     }
#     Write-host "Done calling Invoke-BitlockerEscrow"
#     exit 0
# }

# #endregion functions

# #region execute

# Test-Bitlocker -BitlockerDrive $DriveLetter
# $KeyProtectorId = Get-KeyProtectorId -BitlockerDrive $DriveLetter
# Invoke-BitlockerEscrow -BitlockerDrive $DriveLetter -BitlockerKey $KeyProtectorId

#endregion execute













#region declarations

$DriveLetter = $env:SystemDrive

#endregion declarations

#region functions

function Test-Bitlocker {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$BitlockerDrive
    )
    # Log params
    Log-Params -Parameters @{ BitlockerDrive = $BitlockerDrive }

    try {
        # Tests the drive for existing Bitlocker key protectors
        Write-EnhancedLog -Message "Testing Bitlocker protection on drive $BitlockerDrive" -Level "INFO"
        Get-BitLockerVolume -MountPoint $BitlockerDrive -ErrorAction Stop
    }
    catch {
        Write-EnhancedLog -Message "Bitlocker not found on drive $BitlockerDrive. Terminating script!" -Level "ERROR"
        Handle-Error -ErrorRecord $_
        exit 0
    }
}

function Get-KeyProtectorId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$BitlockerDrive
    )
    # Log params
    Log-Params -Parameters @{ BitlockerDrive = $BitlockerDrive }

    try {
        # Fetches the key protector ID of the drive
        Write-EnhancedLog -Message "Fetching key protector ID for drive $BitlockerDrive" -Level "INFO"
        $BitLockerVolume = Get-BitLockerVolume -MountPoint $BitlockerDrive
        $KeyProtector = $BitLockerVolume.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
        return $KeyProtector.KeyProtectorId
    }
    catch {
        Write-EnhancedLog -Message "Failed to fetch key protector ID for drive $BitlockerDrive" -Level "ERROR"
        Handle-Error -ErrorRecord $_
        return $null
    }
}

function Invoke-BitlockerEscrow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$BitlockerDrive,

        [Parameter(Mandatory = $true)]
        [string[]]$BitlockerKey
    )
    # Log params
    Log-Params -Parameters @{ BitlockerDrive = $BitlockerDrive; BitlockerKey = $BitlockerKey }


    foreach ($Key in $BitlockerKey) {
        try {
            Write-EnhancedLog -Message "Escrowing key protector ID $Key for drive $BitlockerDrive" -Level "INFO"
            BackupToAAD-BitLockerKeyProtector -MountPoint $BitlockerDrive -KeyProtectorId $Key #-ErrorAction SilentlyContinue
        }
        catch {
            Write-EnhancedLog -Message "Failed to escrow key protector ID $Key for drive $BitlockerDrive" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            exit 1
        }
    }
    exit 0
}

#endregion functions

#region execute

Test-Bitlocker -BitlockerDrive $DriveLetter
$KeyProtectorId = Get-KeyProtectorId -BitlockerDrive $DriveLetter
if ($null -ne $KeyProtectorId) {
    Invoke-BitlockerEscrow -BitlockerDrive $DriveLetter -BitlockerKey $KeyProtectorId
}
else {
    Write-EnhancedLog -Message "No key protector ID found, unable to proceed with escrowing" -Level "ERROR"
    exit 1
}

#endregion execute
















