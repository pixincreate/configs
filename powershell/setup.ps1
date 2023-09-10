# Credits: ChrisTitusTech

#If the file does not exist, create it.
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
		 Get-Item -Path $PROFILE | Move-Item -Destination oldprofile.ps1
		 Invoke-RestMethod https://github.com/pixincreate/configs/raw/main/powershell/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
		 Write-Host "The profile @ [$PROFILE] has been created and old profile removed."
 }
& $profile

# OMP Install
#
winget install starship

# Font Install
# Get all installed font families
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families

# Check if FiraCode is installed
if ($fontFamilies -notcontains "FiraCode") {
    
    # Download and install FiraCode
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
winget install starship
starship preset pastel-powerline -o $env:userprofile\.config\starship.toml

# Install Walk, the terminal navigator
irm -Uri "https://github.com/antonmedv/walk/releases/latest/download/walk_windows_amd64.exe" -OutFile "$env:userprofile\.config\walk.exe"

# Terminal Icons Install
Install-Module -Name Terminal-Icons -Repository PSGallery
