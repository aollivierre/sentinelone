<#
.SYNOPSIS

PSApppDeployToolkit - This script performs the installation or uninstallation of an application(s).

.DESCRIPTION

- The script is provided as a template to perform an install or uninstall of an application(s).
- The script either performs an "Install" deployment type or an "Uninstall" deployment type.
- The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.

The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.

PSApppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2024 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham and Muhammad Mashwani).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.PARAMETER DeploymentType

The type of deployment to perform. Default is: Install.

.PARAMETER DeployMode

Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.

.PARAMETER AllowRebootPassThru

Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.PARAMETER TerminalServerMode

Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.

.PARAMETER DisableLogging

Disables logging to file for the script. Default is: $false.

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"

.EXAMPLE

Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"

.INPUTS

None

You cannot pipe objects to this script.

.OUTPUTS

None

This script does not generate any output.

.NOTES

Toolkit Exit Code Ranges:
- 60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
- 69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
- 70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1

.LINK

https://psappdeploytoolkit.com
#>


[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [String]$DeploymentType = 'Install',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [String]$DeployMode = 'Interactive',
    [Parameter(Mandatory = $false)]
    [switch]$AllowRebootPassThru = $false,
    [Parameter(Mandatory = $false)]
    [switch]$TerminalServerMode = $false,
    [Parameter(Mandatory = $false)]
    [switch]$DisableLogging = $false
)

Try {
    ## Set the script execution policy for this process
    Try {
        Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
    } Catch {
    }

    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    ## Variables: Application
    [String]$appVendor = 'Fortinet'
    [String]$appName = 'FortiClient EMS'
    [String]$appVersion = 'Any older than FortiClient VPN V7.4'
    [String]$appArch = ''
    [String]$appLang = 'EN'
    [String]$appRevision = '01'
    [String]$appScriptVersion = '1.0.0'
    [String]$appScriptDate = '22/07/2024'
    [String]$appScriptAuthor = 'AOllivierre'
    ##*===============================================
    ## Variables: Install Titles (Only set here to override defaults set by the toolkit)
    [String]$installName = ''
    [String]$installTitle = ''

    ##* Do not modify section below
    #region DoNotModify

    ## Variables: Exit Code
    [Int32]$mainExitCode = 0

    ## Variables: Script
    [String]$deployAppScriptFriendlyName = 'Deploy Application'
    [Version]$deployAppScriptVersion = [Version]'3.10.1'
    [String]$deployAppScriptDate = '05/03/2024'
    [Hashtable]$deployAppScriptParameters = $PsBoundParameters

    ## Variables: Environment
    If (Test-Path -LiteralPath 'variable:HostInvocation') {
        $InvocationInfo = $HostInvocation
    } Else {
        $InvocationInfo = $MyInvocation
    }
    [String]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

    ## Dot source the required App Deploy Toolkit Functions
    Try {
        [String]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
        If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) {
            Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
        }
        If ($DisableLogging) {
            . $moduleAppDeployToolkitMain -DisableLogging
        } Else {
            . $moduleAppDeployToolkitMain
        }
    } Catch {
        If ($mainExitCode -eq 0) {
            [Int32]$mainExitCode = 60008
        }
        Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        ## Exit the script, returning the exit code to SCCM
        If (Test-Path -LiteralPath 'variable:HostInvocation') {
            $script:ExitCode = $mainExitCode; Exit
        } Else {
            Exit $mainExitCode
        }
    }

    #endregion
    ##* Do not modify section above
    ##*===============================================
    ##* END VARIABLE DECLARATION
    ##*===============================================




    # Read configuration from the JSON file
    # Assign values from JSON to variables

    # Read configuration from the JSON file
    $configPath = Join-Path -Path $PSScriptRoot -ChildPath 'config.json'
    $env:MYMODULE_CONFIG_PATH = $configPath

    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

    function Initialize-Environment {
        param (
            [string]$WindowsModulePath = 'EnhancedBoilerPlateAO\2.0.0\EnhancedBoilerPlateAO.psm1',
            [string]$LinuxModulePath = '/usr/src/code/Modules/EnhancedBoilerPlateAO/2.0.0/EnhancedBoilerPlateAO.psm1'
        )

        function Get-Platform {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                return $PSVersionTable.Platform
            } else {
                return [System.Environment]::OSVersion.Platform
            }
        }

        function Setup-GlobalPaths {
            if ($env:DOCKER_ENV -eq $true) {
                $global:scriptBasePath = $env:SCRIPT_BASE_PATH
                $global:modulesBasePath = $env:MODULES_BASE_PATH
            } else {
                $global:scriptBasePath = $PSScriptRoot
                $global:modulesBasePath = "$PSScriptRoot\modules"
                # $global:modulesBasePath = "c:\code\modules"
            }
        }

        function Setup-WindowsEnvironment {
            # Get the base paths from the global variables
            Setup-GlobalPaths

            # Construct the paths dynamically using the base paths
            $global:modulePath = Join-Path -Path $modulesBasePath -ChildPath $WindowsModulePath
            $global:AOscriptDirectory = Join-Path -Path $scriptBasePath -ChildPath 'Win32Apps-DropBox'
            $global:directoryPath = Join-Path -Path $scriptBasePath -ChildPath 'Win32Apps-DropBox'
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
            $global:AOscriptDirectory = Convert-WindowsPathToLinuxPath -WindowsPath "$PSscriptroot"
            $global:directoryPath = Convert-WindowsPathToLinuxPath -WindowsPath "$PSscriptroot\Win32Apps-DropBox"
            $global:Repo_Path = Convert-WindowsPathToLinuxPath -WindowsPath "$PSscriptroot"
            $global:Repo_winget = "$global:Repo_Path\Win32Apps-DropBox"
        }

        $platform = Get-Platform
        if ($platform -eq 'Win32NT' -or $platform -eq [System.PlatformID]::Win32NT) {
            Setup-WindowsEnvironment
        } elseif ($platform -eq 'Unix' -or $platform -eq [System.PlatformID]::Unix) {
            Setup-LinuxEnvironment
        } else {
            throw 'Unsupported operating system'
        }
    }

    # Call the function to initialize the environment
    Initialize-Environment


    # Example usage of global variables outside the function
    Write-Output 'Global variables set by Initialize-Environment:'
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


    Write-Host 'Starting to call Get-ModulesFolderPath...'

    # Store the outcome in $ModulesFolderPath
    try {
  
        # $ModulesFolderPath = Get-ModulesFolderPath -WindowsPath "C:\code\modules" -UnixPath "/usr/src/code/modules"
        $ModulesFolderPath = Get-ModulesFolderPath -WindowsPath "$PsScriptRoot\modules" -UnixPath "$PsScriptRoot/modules"
        Write-Host "Modules folder path: $ModulesFolderPath"

    } catch {
        Write-Error $_.Exception.Message
    }


    Write-Host 'Starting to call Import-LatestModulesLocalRepository...'
    Import-LatestModulesLocalRepository -ModulesFolderPath $ModulesFolderPath -ScriptPath $PSScriptRoot

    ###############################################################################################################################
    ############################################### END MODULE LOADING ############################################################
    ###############################################################################################################################
    try {
        # Ensure-LoggingFunctionExists -LoggingFunctionName "# Write-EnhancedLog"
        # Continue with the rest of the script here
        # exit
    } catch {
        Write-Host "Critical error: $_" -ForegroundColor Red
        exit
    }

    ###############################################################################################################################
    ###############################################################################################################################
    ###############################################################################################################################

    # Setup logging
    Write-EnhancedLog -Message 'Script Started' -Level 'INFO'

    ################################################################################################################################
    ################################################################################################################################
    ################################################################################################################################


    # ################################################################################################################################
    # ############### CALLING AS SYSTEM to simulate Intune deployment as SYSTEM (Uncomment for debugging) ############################
    # ################################################################################################################################

    # Example usage
    $privateFolderPath = Join-Path -Path $PSScriptRoot -ChildPath 'private'
    $PsExec64Path = Join-Path -Path $privateFolderPath -ChildPath 'PsExec64.exe'
    $ScriptToRunAsSystem = $MyInvocation.MyCommand.Path

    Ensure-RunningAsSystem -PsExec64Path $PsExec64Path -ScriptPath $ScriptToRunAsSystem -TargetFolder $privateFolderPath


    # ################################################################################################################################
    # ############### END CALLING AS SYSTEM to simulate Intune deployment as SYSTEM (Uncomment for debugging) ########################
    # ################################################################################################################################

    # Start-Process -FilePath "$PSScriptRoot\Deploy-Application.exe" -ArgumentList "-DeploymentType `"Uninstall`" -DeployMode `"Interactive`"" -Wait -WindowStyle Hidden







    If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
        ##*===============================================
        ##* PRE-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Installation'

        ## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
        # Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt
        Show-InstallationWelcome -CloseApps 'iexplore' -CheckDiskSpace -PersistPrompt

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Installation tasks here>


        ##*===============================================
        ##* INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Installation'

        ## Handle Zero-Config MSI Installations
        If ($useDefaultMsi) {
            [Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) {
                $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            }
            Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) {
                $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ }
            }
        }

        ## <Perform Installation tasks here>



        $scriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
        Start-Process -FilePath "$scriptDirectory\FortiClientSetup_7.2.3_x64.exe" -ArgumentList '/quiet /norestart' -Wait -WindowStyle Hidden
  
  
  
  
        function WaitForRegistryKey {
            param (
                [string[]]$RegistryPaths,
                [string]$SoftwareName,
                [version]$MinimumVersion,
                [int]$TimeoutSeconds = 120
            )
          
            $elapsedSeconds = 0
          
            while ($elapsedSeconds -lt $TimeoutSeconds) {
                # Write-Output "Checking registry for $SoftwareName version $MinimumVersion or later... (Elapsed time: $elapsedSeconds seconds)"
          
                foreach ($path in $RegistryPaths) {
                    $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
          
                    foreach ($item in $items) {
                        $app = Get-ItemProperty -Path $item.PsPath -ErrorAction SilentlyContinue
                        if ($app.DisplayName -like "*$SoftwareName*") {
                            $installedVersion = New-Object Version $app.DisplayVersion
                            if ($installedVersion -ge $MinimumVersion) {
                                Write-Output "Found $SoftwareName version $installedVersion at $item.PsPath."
                                return @{
                                    IsInstalled = $true
                                    Version     = $app.DisplayVersion
                                    ProductCode = $app.PSChildName
                                }
                            }
                        }
                    }
                }
          
                Start-Sleep -Seconds 1
                $elapsedSeconds++
            }
          
            Write-Output "Timeout reached. $SoftwareName version $MinimumVersion or later not found."
            return @{IsInstalled = $false }
        }
          
          
  
  
  
        # Define constants for registry paths and minimum required version
        $registryPaths = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        )
        $targetSoftwareName = '*FortiClient*'
        $minimumVersion = New-Object Version '7.2.3.0929'
             
  
        # Main script execution block
        $installationCheck = WaitForRegistryKey -RegistryPaths $registryPaths -SoftwareName $targetSoftwareName -MinimumVersion $minimumVersion -TimeoutSeconds 120
  
        if ($installationCheck.IsInstalled) {
            # Write-Output "FortiClientVPN version $($installationCheck.Version) or later is installed."
            # exit 0
        } else {
            # Write-Output "FortiClientVPN version $minimumVersion or later is not installed."
            # exit 1
        }
  
  
  
  
  
  
        Start-Process -FilePath 'reg.exe' -ArgumentList "import `"$scriptDirectory\CBA_National_SSL_VPN_SAML.reg`"" -Wait


        ##*===============================================
        ##* POST-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Installation'

        ## <Perform Post-Installation tasks here>

        ## Display a message at the end of the install
        If (-not $useDefaultMsi) {
            Show-InstallationPrompt -Message 'You should now see FortiClient EMS v7.2.3 in your task bar' -ButtonRightText 'OK' -Icon Information -NoWait
        }
    } ElseIf ($deploymentType -ieq 'Uninstall') {
        ##*===============================================
        ##* PRE-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Uninstallation'

        ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
        Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Uninstallation tasks here>





        ##*===============================================
        ##* UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Uninstallation'

        ## Handle Zero-Config MSI Uninstallations
        If ($useDefaultMsi) {
            [Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) {
                $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            }
            Execute-MSI @ExecuteDefaultMSISplat
        }

        ## <Perform Uninstallation tasks here>



        # ##*===============================================
        # ##* VARIABLE DECLARATION
        # ##*===============================================
        # # Variables: Application Information
        # [string]$installTitle = 'Uninstalling Your Application'
        # # [string]$deferTitle = 'Uninstall Deferment'
        # [string]$deferMessage = 'You have chosen to defer the uninstallation of Your Application. The uninstallation will be retried later.'

        # ##*===============================================
        # ##* FUNCTION DECLARATION
        # ##*===============================================
        # Function Show-DeferPrompt {
        #     <#
        # .SYNOPSIS
        # Show a defer prompt with options to continue or defer.
        # #>
        #     # $deferPromptResult = Show-InstallationPrompt -Message 'Do you want to continue with the uninstallation of Your Application or defer it?' -ButtonRightText 'Defer' -ButtonLeftText 'Continue' -Icon Question

        #     # Define the parameters for Show-InstallationPrompt using a hashtable
        #     $promptParams = @{
        #         Message         = 'Do you want to continue with the uninstallation of Your Application or defer it?'
        #         ButtonRightText = 'Defer'
        #         ButtonLeftText  = 'Continue'
        #         Icon            = 'Question'
        #     }

        #     # Call the Show-InstallationPrompt cmdlet with the splatted parameters
        #     $deferPromptResult = Show-InstallationPrompt @promptParams


        #     If ($deferPromptResult -eq 'Defer') {
        #         Show-InstallationPrompt -Message $deferMessage -ButtonRightText 'OK' -Icon Information
        #         Exit-Script -ExitCode 1618
        #     }
        # }

        # # If ($useDefer) {
        # Show-DeferPrompt
        # }

        ##*===============================================
        ##* SCRIPT EXECUTION
        ##*===============================================
        # # Check for Uninstallation Mode
        # If ($deploymentType -eq 'Uninstall') {
        #     Show-InstallationWelcome -CloseApps 'your_application' -Silent -BlockExecution
        #     If ($useDefer) {
        #         Show-DeferPrompt
        #     }
        #     # Call your uninstall commands here
        #     Execute-MSI -Action 'Uninstall' -Path 'YourMSI.msi'
        #     Show-InstallationProgress -Status 'Uninstalling Your Application...'
        #     Show-InstallationComplete -PromptUser
        # } Else {
        #     # Default installation behavior
        #     Show-InstallationWelcome -CloseApps 'your_application' -Silent -BlockExecution
        #     Execute-MSI -Action 'Install' -Path 'YourMSI.msi'
        #     Show-InstallationProgress -Status 'Installing Your Application...'
        #     Show-InstallationComplete -PromptUser
        # }







        # # Define constants for deferral limits
        # $deferTimes = 3
        # $deferDays = 0  # Not using days for this example, only defer times
        # $deferDeadline = (Get-Date).AddDays(7).ToString('MM/dd/yyyy')  # Arbitrary deadline for demonstration

        # # Show the installation welcome prompt with deferral options
        # # Show-InstallationWelcome -CloseApps 'iexplore,winword,excel' -AllowDefer -DeferTimes $deferTimes -DeferDays $deferDays -DeferDeadline $deferDeadline -BlockExecution
        # # Show-InstallationWelcome -AllowDefer -DeferTimes $deferTimes -DeferDays $deferDays -DeferDeadline $deferDeadline -BlockExecution
        # Show-InstallationWelcome -AllowDefer -DeferTimes $deferTimes -DeferDays $deferDays -DeferDeadline $deferDeadline
        # # Show-InstallationWelcome

        # # Main script execution block for uninstallation
        # $uninstallCompleted = $false

        # While (-not $uninstallCompleted) {
        #     # Show a prompt to continue with the uninstallation or defer
        #     # $deferPromptParams = @{
        #     #     Message         = 'Do you want to continue with the uninstallation of Your Application or defer it?'
        #     #     ButtonRightText = 'Defer'
        #     #     ButtonLeftText  = 'Continue'
        #     #     Icon            = 'Question'
        #     # }

        #     # $deferPromptResult = Show-InstallationPrompt @deferPromptParams

        #     If ($deferPromptResult -eq 'Defer') {
        #         Show-InstallationPrompt -Message 'You have chosen to defer the uninstallation. It will be retried later.' -ButtonRightText 'OK' -Icon Information
        #         Exit-Script -ExitCode 1618  # Exit with SCCM retry code
        #     } ElseIf ($deferPromptResult -eq 'Continue') {
        #         # Proceed with uninstallation
        #         Show-InstallationProgress -Status 'Uninstalling Your Application...'
        
        #         # Call your uninstall commands here
        #         # Execute-MSI -Action 'Uninstall' -Path 'YourMSI.msi'
        
        #         $uninstallCompleted = $true
        #     } Else {
        #         # Handle unexpected response or timeout
        #         # Exit-Script -ExitCode 1
        #     }
        # }



        # If script execution reaches this point, exit with success code
        # Exit-Script -ExitCode 0





# Show the prompt to the user to click "Continue"
$promptParams = @{
    Message         = 'Click "Continue" to proceed with the uninstallation. The system will reboot after the uninstallation.'
    ButtonLeftText  = 'Continue'
    Icon            = 'Warning'
    TopMost         = $true
}

$promptResult = Show-InstallationPrompt @promptParams

# Check the user's response
If ($promptResult -eq 'Continue') {
    # Show progress for the uninstallation
    Show-InstallationProgress -Status 'Uninstalling Your Application...'
    
    try {
        # Call your uninstall commands here
        # Execute-MSI -Action 'Uninstall' -Path 'YourMSI.msi'




        
        # the following does not really remove the EMS 7.2.3 but will keep it in case it removes other older versions
        # Start-Process -FilePath "$scriptDirectory\FortiClientSetup_7.2.3_x64.exe" -ArgumentList '/uninstallfamily /quiet' -Wait

        #instead of manually hard coding the uninstall product code below we will fetch it dynamically to remove any FortiClient product
        # Start-Process -FilePath "MsiExec.exe" -ArgumentList "/X{611804A7-F14E-45A2-9F55-345D33EDD28E} /quiet /forcerestart" -Wait

        
        #here we are dynamically fetching the uninstall string and removing the product
        function Uninstall-FortiClientEMSAgentApplication {
            [CmdletBinding()]
            param()

            begin {
                Write-EnhancedLog -Message 'Starting the uninstall process...' -Level 'INFO'

                $uninstallKeys = @(
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
                )
            }

            process {
                try {
                    $uninstallString = Find-UninstallString -UninstallKeys $uninstallKeys -ApplicationName '*Forti*'

                    if ($null -ne $uninstallString) {
                        Write-EnhancedLog -Message "Found uninstall string: $uninstallString" -Level 'INFO'
                        Invoke-Uninstall -UninstallString $uninstallString
                    } else {
                        Write-EnhancedLog -Message 'Uninstall string not found for FortiClientEMSAgent application.' -Level 'WARNING'
                    }
                } catch {
                    Handle-Error -ErrorRecord $_
                }
            }

            end {
                Write-EnhancedLog -Message 'Uninstall process completed.' -Level 'INFO'
            }
        }

        function Find-UninstallString {
            param (
                [string[]]$UninstallKeys,
                [string]$ApplicationName
            )

            try {
                foreach ($key in $UninstallKeys) {
                    $items = Get-ChildItem -Path $key -ErrorAction SilentlyContinue
                    foreach ($item in $items) {
                        $app = Get-ItemProperty -Path $item.PsPath
                        if ($app.DisplayName -like $ApplicationName) {
                            Write-EnhancedLog -Message "Found application: $($app.DisplayName) with uninstall string: $($app.UninstallString)" -Level 'INFO'
                            return $app.UninstallString
                        }
                    }
                }
                Write-EnhancedLog -Message "No matching application found for: $ApplicationName" -Level 'WARNING'
            } catch {
                Handle-Error -ErrorRecord $_
            }
            return $null
        }

        function Invoke-Uninstall {
            param (
                [string]$UninstallString
            )

            try {
                Write-EnhancedLog -Message 'Starting uninstallation process.' -Level 'INFO'

                # Extract the file path and arguments using a regular expression
                if ($UninstallString -match '(".*?"|\S+)(.*)') {
                    $filePath = $matches[1].Trim('"')
                    # $arguments = $matches[2].Trim() + ' /quiet /forcerestart'
                    $arguments = $matches[2].Trim() + ' /quiet /norestart'

                    Write-EnhancedLog -Message "FilePath: $filePath" -Level 'INFO'
                    Write-EnhancedLog -Message "Arguments: $arguments" -Level 'INFO'

                    Start-Process -FilePath $filePath -ArgumentList $arguments -Wait -WindowStyle Hidden

                    Write-EnhancedLog -Message "Executed uninstallation with arguments: $arguments" -Level 'INFO'
                } else {
                    Write-EnhancedLog -Message "Failed to parse the uninstall string: $UninstallString" -Level 'ERROR'
                }
            } catch {
                Write-EnhancedLog -Message "An error occurred during the uninstallation process: $($_.Exception.Message)" -Level 'ERROR'
                Handle-Error -ErrorRecord $_
            }
        }

        # Uninstall-FortiClientEMSAgentApplication












         
        $identifyingNumber = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like '*forti*' } | Select-Object -ExpandProperty IdentifyingNumber
        # Execute MsiZap.Exe with the retrieved GUID &&  YOU CAN SPECIFY THE PATH FOR THE MSIZAP HERE AFTER DEPLOYED TO LOCAL COMPUTER OF ENDUSERS
 
        if ($identifyingNumber) {
 
        Start-Process -FilePath "$scriptDirectory\MsiZap.Exe" -ArgumentList "TW! $identifyingNumber" -Verb RunAs -Wait
 
        } else {
 
        Write-Host 'No matching software found.'
 
        }


        # Restart-Computer -Force




        
        # Show restart prompt after uninstallation
        Show-InstallationRestartPrompt -CountdownSeconds 600 -CountdownNoHideSeconds 60 -TopMost $true
    } catch {
        # Write-Log -Message "An error occurred during the uninstallation process: $_" -Severity 3
        # Exit-Script -ExitCode 1
    }
} else {
    # Write-Log -Message "Unexpected response or prompt timeout." -Severity 3
    # Exit-Script -ExitCode 1
}

# If script execution reaches this point, exit with success code
# Exit-Script -ExitCode 0










        # # If uninstallation completed, show the restart prompt
        # If ($uninstallCompleted) {
        #     Show-InstallationRestartPrompt -CountdownSeconds 600 -CountdownNoHideSeconds 60 -TopMost $true
        # }


        # *****************************************************************************
        # ********************Uninstall Forticlient / Scrapping it ********************
        # *****************************************************************************
 
        # the following technique has not been tested well yet and will be activated in case the above method with MSI Exec does not work

        # Retrieve the IdentifyingNumber for software with "forti" in the name
 
        # $identifyingNumber = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like '*forti*' } | Select-Object -ExpandProperty IdentifyingNumber
        # # Execute MsiZap.Exe with the retrieved GUID &&  YOU CAN SPECIFY THE PATH FOR THE MSIZAP HERE AFTER DEPLOYED TO LOCAL COMPUTER OF ENDUSERS
 
        # if ($identifyingNumber) {
 
        # Start-Process -FilePath "$scriptDirectory\MsiZap.Exe" -ArgumentList "TW! $identifyingNumber" -Verb RunAs -Wait
 
        # } else {
 
        # Write-Host 'No matching software found.'
 
        # }


        # Restart-Computer -Force


        ##*===============================================
        ##* POST-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Uninstallation'

        ## <Perform Post-Uninstallation tasks here>


    } ElseIf ($deploymentType -ieq 'Repair') {
        ##*===============================================
        ##* PRE-REPAIR
        ##*===============================================
        [String]$installPhase = 'Pre-Repair'

        ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
        Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Repair tasks here>

        ##*===============================================
        ##* REPAIR
        ##*===============================================
        [String]$installPhase = 'Repair'

        ## Handle Zero-Config MSI Repairs
        If ($useDefaultMsi) {
            [Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Repair'; Path = $defaultMsiFile; }; If ($defaultMstFile) {
                $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            }
            Execute-MSI @ExecuteDefaultMSISplat
        }
        ## <Perform Repair tasks here>

        ##*===============================================
        ##* POST-REPAIR
        ##*===============================================
        [String]$installPhase = 'Post-Repair'

        ## <Perform Post-Repair tasks here>


    }
    ##*===============================================
    ##* END SCRIPT BODY
    ##*===============================================

    ## Call the Exit-Script function to perform final cleanup operations
    Exit-Script -ExitCode $mainExitCode
} Catch {
    [Int32]$mainExitCode = 60001
    [String]$mainErrorMessage = "$(Resolve-Error)"
    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode $mainExitCode
}
