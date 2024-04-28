# Credits: ChrisTitusTech
Import-Module .\windows\powershell\modules\vanguard_scheduler.ps1

# Function to check and elevate the script
function Grant-AdminAccess {
    # Ensure the script can run with elevated privileges
    $currentScriptPath = $MyInvocation.MyCommand.Definition
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "Elevating script to admin..."
        if (Get-Command -Name "gsudo" -ErrorAction SilentlyContinue) {
            $output = gsudo $currentScriptPath
            Write-Host $output
            exit
        } else {
            Write-Host "'gsudo' not found, using native elevation..."
            $adminArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$currentScriptPath`""
            $output = Start-Process -FilePath "powershell" -ArgumentList $adminArgs -Verb RunAs -Wait | Out-String
            Write-Host $output
            exit
        }
    }
}

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


# Function to test internet connectivity
function Test-InternetConnection {
    try {
        Test-Connection -ComputerName www.duck.com -Count 1 -ErrorAction Stop
        return $true
    } catch {
        Show-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

# Function to install a FiraCode Nerd Font
function Install-Font {
    try {
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

        if ($fontFamilies -notcontains "FiraCode Nerd Font") {
            Show-Line "Installing FiraCode Nerd Font..."

            # Download and install FiraCode NerdFont
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFileAsync((New-Object System.Uri("https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip")), ".\FiraCode.zip")

            while ($webClient.IsBusy) {
                Start-Sleep -Seconds 2
            }

            Expand-Archive -Path ".\FiraCode.zip" -DestinationPath ".\FiraCode" -Force
            $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
            Get-ChildItem -Path ".\FiraCode" -Recurse -Filter "*.ttf" | ForEach-Object {
                If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                    $destination.CopyHere($_.FullName, 0x10)
                }
            }

            # Clean up
            Remove-Item -Path ".\FiraCode" -Recurse -Force
            Remove-Item -Path ".\FiraCode.zip" -Force
        }
    } catch {
        Show-Error "Failed to download or install the FiraCode Nerd font. Error: $_"
    }
}

# Function to install PowerShell modules
function Install-Module {
    param(
        [string]$moduleNames
    )

    foreach ($moduleName in $moduleNames) {
        try {
            if (-not(Get-Module -Name $moduleName -ListAvailable)) {
                Show-Line "Installing module '$moduleName'..."
                Install-Module -Name $moduleName -Repository PSGallery -Force -ErrorAction Stop
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
            winget install $packageName
        } catch {
            Show-Error "Failed to install package '$packageName'. Error: $_"
        }
    }
}

# Function to download the configs from GitHub repository
function Get-Configs {
    Show-Line "Downloading the configs..."
    git clone "https://github.com/pixincreate/configs.git" "$env:userprofile\Desktop\configs"
    Set-Location "$env:userprofile\Desktop\configs"
}

# Function to restore the powershell profile
function Restore-Profile {
    # Profile creation or update
    if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
        try {
            # Detect Version of PowerShell & Create Profile directories if they do not exist.
            $profilePath = ""
            if ($PSVersionTable.PSEdition -eq "Core") {
                $profilePath = "$env:userprofile\Documents\Powershell"
            } elseif ($PSVersionTable.PSEdition -eq "Desktop") {
                $profilePath = "$env:userprofile\Documents\WindowsPowerShell"
            }

            if (!(Test-Path -Path $profilePath)) {
                New-Item -Path $profilePath -ItemType "directory"
            }

            Invoke-RestMethod https://github.com/pixincreate/configs/raw/main/windows/powershell/Microsoft.PowerShell_profile.ps1 -OutFile "$PROFILE"
            Copy-Item -Path "$PROFILE" -Destination "$profilePath\Microsoft.VSCode_profile.ps1"

            Show-Line "The profile @ [$PROFILE] has been created."
            Show-Line "If you want to add any persistent components, please do so at [$profilePath\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
        } catch {
            Show-Error "Failed to create or update the profile. Error: $_"
        }

        # Check if the user uses Valorant and install the Vanguard controller
        $usesValorant = Read-Host -Prompt "Do you use Valorant? (y/n) Default: y"
        if (-not $usesValorant -eq "n") {
            if (-not (Test-Path -Path "$profilePath\Modules")) {
                New-Item -Path "$profilePath\Modules" -ItemType "directory"
            }
            Invoke-RestMethod https://github.com/pixincreate/configs/raw/main/windows/powershell/modules/vanguard.ps1 -OutFile "$profilePath\Modules\vanguard.ps1"
            Invoke-RestMethod https://github.com/pixincreate/configs/raw/main/windows/powershell/modules/scheduler.ps1 -OutFile "$profilePath\Modules\scheduler.ps1"
            Show-Line "Installation of Rootkit (Vanguard) controller completed."
            $setupScheduler = Read-Host -Prompt "Do you want to set up a scheduler task to disable Vanguard after gameplay? (y/n) Default: y"
            if (-not $setupScheduler -eq "n") {
                try {
                    Install-ScheduledTask
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
            Invoke-RestMethod https://github.com/pixincreate/configs/raw/main/windows/powershell/Microsoft.PowerShell_profile.ps1 -OutFile "$PROFILE"
            Copy-Item -Path "$PROFILE" -Destination "$profilePath\Microsoft.VSCode_profile.ps1"

            Show-Line "The profile @ [$PROFILE] has been created and old profile backed up."
            Show-Line "Please back up any persistent components of your old profile to [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
        } catch {
            Show-Error "Failed to backup and update the profile. Error: $_"
        }
    }
}

# Function to Configure the developer environment
function Configure {
    # Setup the terminal
    Show-Line "Setting up Terminal ..."
    & ".\windows\powershell\modules\file_copy.ps1" -sourceDirectory ".\home\.config\wt\LocalState\" -destinationBaseDirectory "$env:userprofile\AppData\Local\Packages\" -pattern "Microsoft.WindowsTerminal_*" -fileName "settings.json"

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

    # Configure direnv
    Show-Line "Configuring direnv on user level..."
    [Environment]::SetEnvironmentVariable('DIRENV_CONFIG', '%APPDATA%\direnv\conf', 'User')
    [Environment]::SetEnvironmentVariable('XDG_CACHE_HOME', '%APPDATA%\direnv\cache', 'User')
    [Environment]::SetEnvironmentVariable('XDG_DATA_HOME', '%APPDATA%\direnv\data', 'User')

    # Restore VSCode settings.json
    Show-Line "Restoring VSCode settings.json..."
    Copy-Item -Path "./home/Code/User/settings.json" -Destination "$env:APPDATA\Code\User\settings.json"

    Restore-Profile
}

# Function to install WSL
function Install-WSL {
    Show-Line "Installing Debian WSL..."

    wsl --install
    # Place the installer in startup directory just so that the installation starts at next start up
    Copy-Item -Path "./windows/powershell/modules/wsl_install.cmd" -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\wsl_install.cmd"

    Show-Line "Restarting PC..."
    Restart-Computer
}

# Main function
function main {
    ## Variables
    $modules = @(
        "Terminal-Icons",
        "WalInterop"
    )
    $packages = @(
        "ajeetdsouza.zoxide",
        "dandavison.delta",
        "direnv.direnv",
        "gerardog.gsudo",
        "Git.Git",
        "junegunn.fzf",
        "Microsoft.PowerShell",
        "Microsoft.VisualStudio.2022.BuildTools",
        "Microsoft.VisualStudioCode.Insiders",
        "Neovim.Neovim",
        "Rustlang.Rustup",
        "Starship.Starship",
        "topgrade-rs.topgrade",
        "zyedidia.micro"
    )

    # Check for internet connectivity before proceeding
    if (-not (Test-InternetConnection)) {
        break
    }

    Grant-AdminAccess
    Install-Font
    Install-Module -moduleNames $modules
    Install-Package -packageNames $packages
    Get-Configs
    Configure # Elephant in the room
    Install-WSL
}

# Run the main function
main
