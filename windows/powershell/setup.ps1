# Credits: ChrisTitusTech

function print_line() {
    Write-Output "--------------------------------------------------"
    Write-Output "$args"
}

# Font Install
# Get all installed font families
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families

# Check if FiraCode is installed
if ($fontFamilies -notcontains "FiraCode Nerd Font") {
    print_line "Installing FiraCode Nerd Font..."
    # Download and install FiraCode NerdFont
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile("https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip", ".\FiraCode.zip")

    Expand-Archive -Path ".\FiraCode.zip" -DestinationPath ".\FiraCode" -Force
    $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
    Get-ChildItem -Path ".\FiraCode" -Recurse -Filter "*.ttf" | ForEach-Object {
        If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {        
            # Install font
            $destination.CopyHere($_.FullName, 0x10)
        }
    }

    # Clean up
    Remove-Item -Path ".\FiraCode" -Recurse -Force
    Remove-Item -Path ".\FiraCode.zip" -Force
}

# Install packages
print_line "Installing Packages:\nDelta\nGit\nGSudo\nStarship\nZoxide\nMicro\nDirenv"
winget install dandavison.delta git.git gsudo starship zoxide zyedidia.micro direnv

# Download the repository
git clone "https://github.com/pixincreate/configs.git" "$env:userprofile\Desktop\configs"
Set-Location "$env:userprofile\Desktop\configs"

# Setup the terminal
print_line "Setting up Terminal ..."
& ".\windows\powershell\modules\file_copy.ps1" -sourceDirectory ".\home\.config\wt\LocalState\" -destinationBaseDirectory "$env:userprofile\AppData\Local\Packages\" -pattern "Microsoft.WindowsTerminal_*" -fileName "settings.json"

print_line "Creating configs..."
if (-not (Test-Path -Path "$env:userprofile\.config" -PathType Container)) {
    New-Item -Path "$env:userprofile\.config" -ItemType Directory
}

# Disable telemetry sent by powershell
print_line "Disabling powershell telemetry..."
[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')

print_line "Writing Starship configs..."
Start-Process -Wait powershell.exe -ArgumentList "starship preset pastel-powerline -OutFile $env:userprofile\.config\starship.toml"

# Install Walk, the terminal navigator
print_line "Installing terminal navigator..."
Invoke-RestMethod -Uri "https://github.com/antonmedv/walk/releases/latest/download/walk_windows_amd64.exe" -OutFile "$env:userprofile\.config\walk.exe"

# Terminal Icons Install
print_line "Installing PSGallery module..."
Install-Module -Name Terminal-Icons -Repository PSGallery -Force

# Install WSL Interop
print_line "Installing WSL Interop..."
Install-Module -Name WslInterop -Repository PSGallery -Force

# If the file does not exist, create it.
print_line "Writing powershell profile to the current terminal..."
if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        # Detect Version of Powershell & Create Profile directories if they do not exist.
        if ($PSVersionTable.PSEdition -eq "Core" ) { 
            if (!(Test-Path -Path ($env:userprofile + "\Documents\Powershell"))) {
                New-Item -Path ($env:userprofile + "\Documents\Powershell") -ItemType "directory"
            }
        }
        elseif ($PSVersionTable.PSEdition -eq "Desktop") {
            if (!(Test-Path -Path ($env:userprofile + "\Documents\WindowsPowerShell"))) {
                New-Item -Path ($env:userprofile + "\Documents\WindowsPowerShell") -ItemType "directory"
            }
        }

        Invoke-RestMethod https://github.com/pixincreate/configs/raw/main/windows/powershell/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created."
    }
    catch {
        throw $_.Exception.Message
    }
}
# If the file already exists, forcefully override the existing profile
else {
    Get-Item -Path $PROFILE | Move-Item -Destination oldprofile.ps1 -Force
    Invoke-RestMethod https://github.com/pixincreate/configs/raw/main/windows/powershell/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
    Write-Host "The profile @ [$PROFILE] has been created and old profile removed."
}
& $profile

# Restore VSCode settings.json
print_line "Restoring VSCode settings.json..."
Copy-Item -Path ./home/Code/User/settings.json -Destination $env:APPDATA\Code\User\settings.json

# Install Debian WSL
print_line "Installing Debian WSL..." 
wsl --install

# Place the installer in startup directory just so that the installation starts at next start up
Copy-Item -Path "./windows/powershell/modules/wsl_install.cmd" -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\wsl_install.cmd"

print_line "Restarting PC..."
Restart-Computer
