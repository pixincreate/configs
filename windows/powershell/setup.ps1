#Requires -RunAsAdministrator

param (
    [string[]]$setupParams
)

# DECLARATIONS
# These values can be overrided by exporting them in the shell as environment variables
$REPO_URL = "https://github.com/pixincreate/configs"

$GITCONFIG_EMAIL = "69745008+pixincreate@users.noreply.github.com"
$GITCONFIG_USERNAME = "PiX"
$GITCONFIG_SIGNING_KEY = "~/.ssh/id_ed25519_sign.pub"

$RESTORE_DATA = $false

# Functions to print a message with a timestamp
function Show-Error {
    Write-Error "[$((Get-Date).ToString('HH:mm:ss'))] $args"
}

function Show-Line {
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $args"
}

function Show-Warning {
    Write-Warning "[$((Get-Date).ToString('HH:mm:ss'))] $args"
}

function Write-Prompt($question) {
    Read-Host -Prompt $question"? (y/n). Default (y)"
}

function Test-PWD {
    if ( -not (Split-Path -Leaf (Get-Location).Path) -eq "configs" ) {
        Show-Error "Please run the script from the 'configs' directory."
        exit
    }

}

# Function to test internet connectivity
function Test-InternetConnection {
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadString("http://duck.com") | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Disable Ads and Trackers in Windows
function Debloat {
    Test-PWD

    $disableAds = Write-Prompt "Do you want to disable ads in Windows 11 with OFGB (Oh Frick Go Back)"
    if (-not ($disableAds -eq "n")) {
        # Download and run OFGB
        Show-Line "Downloading and running OFGB..."
        Show-Warning "You might have to install .NET8.0 Desktop Runtime if you haven't already."
        Invoke-RestMethod "https://github.com/xM4ddy/OFGB/releases/latest/download/OFGB.exe" -OutFile ".\windows\tools\ofgb\OFGB.exe"
        Start-Process -Wait ".\windows\tools\ofgb\OFGB.exe" -Verb RunAs
    } else {
        Show-Line "Disabling ads in Windows 11 skipped."
    }

    Show-Line "Disabling powerhell telemetry..."
    [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 1, 'Machine')

    $executeWinutil = Write-Prompt "Do you want to run WinUtil to disable all Microsoft tracking services"
    if (-not ($executeWinutil -eq "n")) {
        Show-Line "Running WinUtil..."
        Invoke-RestMethod "https://christitus.com/win" | Invoke-Expression
        Show-Line "You can also run WinUtil from terminal directly by typing 'winutil' and pressing enter."
    } else {
        Show-Line "WinUtil execution skipped."
    }

    $debloat = Write-Prompt "Do you want to remove Phone Link app"

    if (-not ($debloat -eq "n")) {
        Show-Line "(requires elevation) Debloating your windows..."
        Get-AppxPackage Microsoft.YourPhone -AllUsers | Remove-AppxPackage
    } else {
        Show-Line "Phone Link app is intact and untouched."
    }
}

# Function to install a FiraCode Nerd Font
function Install-Font {
    try {
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families | Select-Object -ExpandProperty Name

        if ($fontFamilies -notcontains "FiraCode Nerd Font") {
            Show-Line "Installing FiraCode Nerd Font..."

            # Download and install FiraCode NerdFont
            $zipPath = ".\FiraCode.zip"
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFileAsync((New-Object System.Uri("https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip")), $zipPath)

            while ($webClient.IsBusy) {
                Start-Sleep -Seconds 2
            }

            Expand-Archive -Path $zipPath -DestinationPath ".\FiraCode" -Force
            $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)

            Get-ChildItem -Path ".\FiraCode" -Recurse -Filter "*.ttf" | ForEach-Object {
                If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                    $destination.CopyHere($_.FullName, 0x10)
                }
            }

            # Clean up
            Remove-Item -Path ".\FiraCode" -Recurse -Force
            Remove-Item -Path $zipPath -Force
        } else {
            Show-Line "FiraCode Nerd Font is already installed."
        }
    } catch {
        Show-Error "Failed to download or install the FiraCode Nerd font. Error: $_"
        if (Test-Path $zipPath) {
            Remove-Item -Path $zipPath -Force
        }
    }
}

# Function to install PowerShell modules
function Install-Module {
    param(
        [string[]]$moduleNames
    )

    foreach ($moduleName in $moduleNames) {
        try {
            if (-not(Get-Module -Name $moduleName -ListAvailable)) {
                Show-Line "Installing module '$moduleName'..."
                Install-Module -Name $moduleName -Repository PSGallery -Force -ErrorAction Stop
                Show-Line "Module '$moduleName' installed successfully."
            } else {
                Show-Line "Module '$moduleName' is already installed."
            }
        } catch {
            Show-Error "Failed to install module '$moduleName'. Error: $_"
        }
    }
}

# Function to install packages using winget
function Install-Package {
    param(
        [string[]]$packageNames
    )

    foreach ($packageName in $packageNames) {
        try {
            Show-Line "Installing package '$packageName'..."
            # If `time and region` is set to world during initial setup, `msstore` does not work.
            # winget first looks at `msstore` and fails installing. Hence, we hard code the `source`
            if ($packageName -eq "Microsoft.VisualStudioCode") {
                Show-Line "Installing VSCode to `machine` while ensuring Path and Shell integration"
                winget install --id=$packageName -e --accept-source-agreements --accept-package-agreements --source winget --override '/VERYSILENT /SP- /MERGETASKS="!runcode,!desktopicon,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"'
            } else {
                winget install --id=$packageName -e --accept-source-agreements --accept-package-agreements --source winget
            }
        } catch {
            Show-Error "Failed to install package '$packageName'. Error: $_"
        }
    }
}

function Install-Packages {
    # define variables
    $modules = @(
        "ps2exe",
        "Terminal-Icons",
        "WslInterop"
    )
    $packages = @(
        # Applications
        "Giorgiotani.Peazip",
        "Bitwarden.Bitwarden",
        "LocalSend.LocalSend",
        "Nvidia.GeForceExperience", # There exist no open source alternative for this
        "Obsidian.Obsidian",
        "OBSProject.OBSStudio",
        "ONLYOFFICE.DesktopEditors",
        "Oracle.VirtualBox",
        "qBittorrent.qBittorrent",

        # Browser
        "Brave.Brave.Beta",
        "Mozilla.Firefox.DeveloperEdition",

        # Cloud
        "FilenCloud.FilenSync",
        "Proton.ProtonDrive",
        "SyncTrayzor.SyncTrayzor",

        # Communication
        "OpenWhisperSystems.Signal",

        # Developer Tools
        "Git.Git",
        "Hugo.Hugo.Extended",
        "Kitware.CMake",
        "Microsoft.DotNet.DesktopRuntime.8",
        "OpenJS.NodeJS.LTS",
        "Microsoft.PowerToys",

        # Games
        "Valve.Steam",

        # IDEs
        "Google.AndroidStudio",
        "JetBrains.IntelliJIDEA.Community",
        "JetBrains.PyCharm.Community",
        "Microsoft.VisualStudioCode",

        # Languages
        "Microsoft.VisualStudio.2022.BuildTools",
        "Oracle.JDK",
        "Python.Python",
        "Rustlang.Rustup",
        "zig.zig",

        # Networking tools
        "NTKERNEL.WireSockVPNClient",
        "Safing.Portmaster",

        # Terminal
        "Microsoft.PowerShell",

        # Terminal Tools
        "ajeetdsouza.zoxide",
        "BurntSushi.ripgrep.MSVC",
        "dandavison.delta",
        "direnv.direnv",
        "eza-community.eza",
        "gerardog.gsudo",
        "junegunn.fzf",
        "Microsoft.WindowsTerminal",
        "Neovim.Neovim",
        "openssl",
        "sharkdp.bat",
        "Starship.Starship",
        "topgrade-rs.topgrade",
        "zyedidia.micro"
    )

    Install-Module -moduleNames $modules
    Install-Package -packageNames $packages
}

function Get-Configs {
    Show-Line "Downloading the configs..."
    git clone "$REPO_URL.git" "$env:userprofile\Downloads\configs"
    Set-Location "$env:userprofile\Downloads\configs"

    Import-Module .\windows\powershell\modules\vanguard_scheduler.ps1
}

function Restore-Data {
    Test-PWD

    Show-Line "Restoring developer data..."

    # Define paths
    $configSrc = "./home/.config"
    $sshSrc = "./home/.ssh"
    $codeSrc = "./home/Code"
    $gitConfigSrc = "./home/.gitconfig"

    # Copy .config if it doesn't exist
    if (-not (Test-Path "$HOME\.config")) {
        Copy-Item -Path $configSrc -Destination "$HOME\.config" -Recurse -Force
    } else {
        Show-Line "Handling individual `config` files and directories..."
        Copy-Item -Path "$configSrc/*" -Destination "$HOME\.config" -Recurse -Force
    }

    # Copy .ssh if it doesn't exist
    if (-not (Test-Path "$HOME\.ssh")) {
        Copy-Item -Path $sshSrc -Destination "$HOME\.ssh" -Recurse -Force
    } else {
        Show-Line "Handling individual `ssh` files and directories..."
        Copy-Item -Path "$sshSrc/*" -Destination "$HOME\.ssh" -Recurse -Force
    }

    # Copy Code User settings
    if (-not (Test-Path "$env:APPDATA\Code\User")) {
        Copy-Item -Path $codeSrc -Destination "$env:APPDATA\Code\User" -Recurse -Force
    } else {
        Show-Line "Handling individual `Code` files and directories..."
        Copy-Item -Path "$codeSrc/*" -Destination "$env:APPDATA\Code\User" -Recurse -Force
    }

    # Copy .gitconfig
    Copy-Item -Path $gitConfigSrc -Destination "$HOME\.gitconfig" -Force

    Show-Line "Developer data restored."
    $RESTORE_DATA = $true
}

function Restore-Profile {
    # Powershell 7 is recommended to be the default. Execute Winutil to set Powershell 7 as default in a click
    # Profile creation or update
    if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
        try {
            # Detect Version of PowerShell & Create Profile directories if they do not exist.
            $profilePath = ""

            # Set paths depending on the version of PowerShell
            if ($PSVersionTable.PSEdition -eq "Core") {
                $profilePath = "$env:userprofile\Documents\PowerShell"
            } elseif ($PSVersionTable.PSEdition -eq "Desktop") {
                $profilePath = "$env:userprofile\Documents\WindowsPowerShell"
            }

            # Create Powershell Directory if does not exist
            if (!(Test-Path -Path $profilePath)) {
                New-Item -Path $profilePath -ItemType "directory"
            }

            # Download PowerShell profile from GitHub
            Invoke-RestMethod "$REPO_URL/raw/main/windows/powershell/Microsoft.PowerShell_profile.ps1" -OutFile "$PROFILE"
            Copy-Item -Path "$PROFILE" -Destination "$profilePath\Microsoft.VSCode_profile.ps1"

            Show-Line "The profile @ [$PROFILE] has been created."
            Show-Line "If you want to add any persistent components, please do so at [$profilePath\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
        } catch {
            Show-Error "Failed to create or update the profile. Error: $_"
        }

        # Ask if the user plays Valorant and wants to install the Vanguard controller
        $usesValorant = Write-Prompt "Do you play Valorant"
        if (-not ($usesValorant -eq "n")) {
            if (-not (Test-Path -Path "$profilePath\Modules")) {
                New-Item -Path "$profilePath\Modules" -ItemType "directory"
            }

            Invoke-RestMethod "$REPO_URL/raw/main/windows/powershell/modules/vanguard.ps1" -OutFile "$profilePath\Modules\vanguard.ps1"
            Invoke-RestMethod "$REPO_URL/raw/main/windows/powershell/modules/vanguard_scheduler.ps1" -OutFile "$profilePath\Modules\vanguard_scheduler.ps1"

            Show-Line "Installation of Rootkit (Vanguard) controller completed."

            $setupScheduler = Write-Prompt "Do you want to set up a scheduler task to disable Vanguard after gameplay"
            if (-not ($setupScheduler -eq "n")) {
                try {
                    Install-ScheduledTask $profilePath
                } catch {
                    Show-Error "Failed to set up the scheduler task. Error: $_"
                }
            }
        } else {
            Show-Line "Installation of Rootkit (Vanguard) controller skipped."
        }
    } else {
        # Backup the old profile and update the profile forcefully if it exist already
        try {
            Get-Item -Path $PROFILE | Move-Item -Destination "oldProfile.ps1" -Force
            Invoke-RestMethod "$REPO_URL/raw/main/windows/powershell/Microsoft.PowerShell_profile.ps1" -OutFile "$PROFILE"
            Copy-Item -Path "$PROFILE" -Destination "$profilePath\Microsoft.VSCode_profile.ps1"

            Show-Line "The profile @ [$PROFILE] has been created and old profile backed up."
            Show-Line "Please back up any persistent components of your old profile to [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
        } catch {
            Show-Error "Failed to backup and update the profile. Error: $_"
        }
    }
}

function Update-GitConfigData {
    # Define the path to the Git config file
    $gitConfigPath = "$HOME\.gitconfig"

    # Read the contents of the Git config file
    $gitConfigContent = Get-Content -Path $gitConfigPath

    # Update the email and username in the Git config
    $gitConfigContent = $gitConfigContent -replace 'email = example@email.com', "email = $GITCONFIG_EMAIL"
    $gitConfigContent = $gitConfigContent -replace 'name = username', "name = $GITCONFIG_USERNAME"
    $gitConfigContent = $gitConfigContent -replace 'signingkey = ~/.ssh/signingkey', "signingkey = $GITCONFIG_SIGNING_KEY"

    # Write the updated content back to the Git config file
    $gitConfigContent | Set-Content -Path $gitConfigPath

    # Optionally, you can create a backup if needed
    Copy-Item -Path $gitConfigPath -Destination "$gitConfigPath.bak" -Force
}

function Set-DeveloperEnvironment {
    Test-PWD

    if (-not $RESTORE_DATA) {
        Show-Warning "Developer data has not been restored. Restoring data prior to setting up the developer environment."
        Restore-Data
    }

    # Terminal Setup
    Show-Line "Setting up the terminal..."
    if ($RESTORE_DATA) {
        Move-Item -Path "$env:userprofile/.config/wt/LocalState/settings.json" -Destination "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Force
    } else {
        Copy-Item -Path "./home/.config/wt/LocalState/settings.json" -Destination "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Force
    }

    # Create the .config directory if it doesn't exist
    Show-Line "Creating configs..."
    if (-not (Test-Path -Path "$env:userprofile\.config" -PathType Container)) {
        New-Item -Path "$env:userprofile\.config" -ItemType Directory
    }

    Show-Line "Writing Starship configs..."
    try {
        Start-Process -Wait powershell.exe -ArgumentList "starship preset catppuccin -OutFile $env:userprofile\.config\starship.toml" -ErrorAction Stop
    } catch {
        Show-Warning "Failed to write Starship configs. Error: $_"
        Copy-Item -Path "./home/.config/starship.toml" -Destination "$env:userprofile\.config\starship.toml"
    }

    Show-Line "Setting up Git..."
    Copy-Item -Path "./home/.gitconfig" -Destination "$env:userprofile\.gitconfig"
    Update-GitConfigData

    # Configure direnv for Windows
    Show-Line "Configuring direnv on user level..."
    [Environment]::SetEnvironmentVariable('DIRENV_CONFIG', '%APPDATA%\direnv\conf', 'User')
    [Environment]::SetEnvironmentVariable('XDG_CACHE_HOME', '%APPDATA%\direnv\cache', 'User')
    [Environment]::SetEnvironmentVariable('XDG_DATA_HOME', '%APPDATA%\direnv\data', 'User')

    # Restore VSCode settings.json
    Show-Line "Restoring VSCode settings.json..."
    Copy-Item -Path "./home/Code/User/settings.json" -Destination "$env:APPDATA\Code\User\settings.json"

    Restore-Profile
}

# Function to install LSW (Linux Subsystem for Windows it is.)
function Install-LSW {
    Show-Line "Setting up Debian LSW (Linux Subsystem for Windows)..."

    wsl --install -d Debian

    Show-Line "Set up your LSW by executing dotfiles.sh to set up Debian:"
    Show-Line "sudo apt-get update && sudo apt-get install -y curl git wget zsh && curl -sSL https://github.com/pixincreate/configs/blob/main/unix/setup.sh | bash"
}

function main {
    # Check for internet connectivity before proceeding
    if (-not (Test-InternetConnection)) {
        Show-Line "No internet connection. Exiting."
        return
    }

    # If no specific functions are provided, run all
    if (-not $setupParams) {
        $setupParams = @("Get-Configs", "Install-Font", "Install-Packages", "Debloat", "Restore-Data", "Set-DeveloperEnvironment", "Install-LSW")
    }

    foreach ($executor in $setupParams) {
        if (Get-Command $executor -ErrorAction SilentlyContinue) {
            Show-Line "Running $executor..."
            & $executor  # Call the function
        } else {
            Show-Error "Function $executor does not exist!"
            Write-Host @"
Available functions:
Get-Configs
Install-Font
Install-Packages
Debloat
Restore-Data
Set-DeveloperEnvironment
Install-LSW
"@
        }
    }
}

# Call the main function
main
