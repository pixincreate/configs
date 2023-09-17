# Credits: ChrisTitusTech

# Font Install
# Get all installed font families
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families

# Check if FiraCode is installed
if ($fontFamilies -notcontains "FiraCode Nerd Font") {
    Write-Output "Installing FiraCode Nerd Font..."
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

# Starship Install
Write-Output "Installing Starship..."
winget install starship

Write-Output "Creating Configs..."
if (-not (Test-Path -Path ".\ .config" -PathType Container)) {
    New-Item -ItemType Directory -Name ".config"
    Write-Host "Directory '.config' created!"
}

Write-Output "Writing Starship configs..."
Start-Process -Wait powershell.exe -ArgumentList "starship preset pastel-powerline -o $env:userprofile\.config\starship.toml"

# Install Walk, the terminal navigator
Write-Output "Installing terminal navigator..."
irm -Uri "https://github.com/antonmedv/walk/releases/latest/download/walk_windows_amd64.exe" -OutFile "$env:userprofile\.config\walk.exe"

# Install Winutil, the windows utility
Write-Output "Installing winutil..."
irm -Uri "https://github.com/pixincreate/configs/raw/main/extra/Winutil/winutil.exe" -OutFile "$env:userprofile\.config\winutil.exe"

# Terminal Icons Install
Write-Output "Installing PSGallery module..."
Install-Module -Name Terminal-Icons -Repository PSGallery -Force

# Install GSudo
Write-Output "Installing GSudo through winget..."
winget install gsudo

# If the file does not exist, create it.
Write-Output "Writing powershell profile to the current terminal..."
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

        Invoke-RestMethod https://github.com/pixincreate/configs/raw/main/powershell/Microsoft.PowerShell_profile.ps1 -o $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created."
    }
    catch {
        throw $_.Exception.Message
    }
}
# If the file already exists, show the message and do nothing.
 else {
		 Get-Item -Path $PROFILE | Move-Item -Destination oldprofile.ps1 -Force
		 Invoke-RestMethod https://github.com/pixincreate/configs/raw/main/powershell/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
		 Write-Host "The profile @ [$PROFILE] has been created and old profile removed."
 }
& $profile
