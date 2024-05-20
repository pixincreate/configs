# --------------------------------------------------------------------------------------------------------------------------------------------
# This file was created by PiX.
# Date: 29/07/2023
# Description: This file contains the profile for PowerShell Core along with some useful functions and aliases to make working with powershell easier and
# intutive with that of Unis based OSes.
# Since working on Mac for office work has greatly increased my productivity, I wanted to have a similar experience on Windows as well and hence
# I wanted to have a similar unix based experience on Windows as well. Started with re-writing small commands such as `touch` and `ls` and then
# found ChrisTitus Tech's powershell profile and decided to add his work on top of my customization.
# This file also includes starship profile as well.
# --------------------------------------------------------------------------------------------------------------------------------------------

# Import Modules and External Profiles
# Ensure Terminal-Icons module is installed before importing
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}

Import-Module -Name Terminal-Icons

# A function to get the file hash only if the file exists, else return null
function Get-ValidatedFileHash {
    param (
        [string]$filePath
    )
    if (Test-Path $filePath) {
        return Get-FileHash $filePath
    } else {
        Write-Warning "File not found: $filePath"
        return $null
    }
}

# Check for Profile Updates
function Update-Profile {
    Write-Host -NoNewLine "Checking for profile updates..."
    try {
        $profileUpdated = $false
        $urls = @(
            "https://github.com/pixincreate/configs/raw/main/windows/powershell/Microsoft.PowerShell_profile.ps1",
            "https://github.com/pixincreate/configs/raw/main/windows/powershell/modules/vanguard.ps1",
            "https://github.com/pixincreate/configs/raw/main/windows/powershell/modules/vanguard_scheduler.ps1"
        )

        $profilePaths = @()
        if ($PSVersionTable.PSEdition -eq "Core") {
            $profilePaths += "$env:userprofile\Documents\PowerShell"
            $profilePaths += "$env:userprofile\Documents\WindowsPowerShell"
        } elseif ($PSVersionTable.PSEdition -eq "Desktop") {
            $profilePaths += "$env:userprofile\Documents\WindowsPowerShell"
        }

        foreach ($profilePath in $profilePaths) {
            $profileFile = Join-Path $profilePath "Microsoft.PowerShell_profile.ps1"
            $vanguardFile = Join-Path $profilePath "Modules\vanguard.ps1"
            $vanguardSchedulerFile = Join-Path $profilePath "Modules\vanguard_scheduler.ps1"

            $oldHashes = @(
                Get-ValidatedFileHash -filePath $profileFile
                Get-ValidatedFileHash -filePath $vanguardFile
                Get-ValidatedFileHash -filePath $vanguardSchedulerFile
            )

            foreach ($url in $urls) {
                $newFileName = $(Split-Path -Leaf $url)
                Invoke-RestMethod $url -OutFile "$env:temp/$newFileName"
                $newHash = Get-FileHash "$env:temp/$newFileName"

                foreach ($oldHash in $oldHashes) {
                    $oldFileName = $(Split-Path -Leaf $oldHash.Path)
                    if ($oldFileName -eq $newFileName) {
                        if ($newHash.Hash -ne $oldHash.Hash) {
                            Copy-Item -Path "$env:temp/$newFileName" -Destination $oldHash.Path -Force

                            if ($oldHash.Path -eq $PROFILE) {
                                Copy-Item -Path "$PROFILE" -Destination "$profilePath\Microsoft.VSCode_profile.ps1" -Force
                            }
                            Write-Host -NoNewLine "`rPlease restart your shell to reflect changes".PadRight(100, " ") -ForegroundColor Magenta
                            $profileUpdated = $true
                        }
                    }
                }
            }
        }
        if (-not $profileUpdated) {
            Write-Host "`rProfile is up to date!".PadRight(100, " ") -ForegroundColor Green
        }
    } catch {
        Write-Error "Update check failed due to: $_"
        Write-Host "Try elevating with 'sudo' and running 'Update-Profile' to force an update." -ForegroundColor Yellow
    } finally {
        Remove-Item -Path "$env:temp/*.ps1" -Force
    }
}

# Admin Check and Prompt Customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}
$adminSuffix = if ($isAdmin) { " [SUDO]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

function Grant-AdminAccess {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "Elevating to admin..."
        if (Get-Command -Name "gsudo" -ErrorAction SilentlyContinue) {
            $output = gsudo $args | Out-String
            Write-Host $output
            break
        } else {
            Write-Host "'gsudo' not found, using native elevation..."
            $adminArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$args`""
            $output = Start-Process -FilePath "powershell" -ArgumentList $adminArgs -Verb RunAs -Wait | Out-String
            Write-Host $output
            break
        }
    }
}

# Utility Functions
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

# Editor Configuration
$EDITOR = if (Test-CommandExists nvim) { 'nvim' }
elseif (Test-CommandExists pvim) { 'pvim' }
elseif (Test-CommandExists vim) { 'vim' }
elseif (Test-CommandExists vi) { 'vi' }
elseif (Test-CommandExists code) { 'code' }
elseif (Test-CommandExists notepad++) { 'notepad++' }
elseif (Test-CommandExists sublime_text) { 'sublime_text' }
else { 'notepad' }
Set-Alias -Name vim -Value $EDITOR

function Edit-Profile {
    vim $PROFILE.CurrentUserAllHosts
}

# touch command in powershell
function touch {
    if ((Test-Path -Path ($args[0])) -eq $false) {
        Set-Content -Path ($args[0]) -Value ($null)
    } else {
        (Get-Item ($args[0])).LastWriteTime = Get-Date
    }
}

# find-file
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# Network Utilities
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }

# System Utilities
function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name = 'LastBootUpTime'; Expression = { $_.ConverttoDateTime($_.lastbootuptime) } } | Format-Table -HideTableHeaders
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

# Reload the powershell profile
function reload {
    & $PROFILE
}

# Reload the console
function recons {
    Clear-Host
    Get-Process -Id $PID | Select-Object -ExpandProperty Path | ForEach-Object { Invoke-Command { & "$_" } -NoNewScope }
}

function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}
function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function df {
    get-volume
}

function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value
}

function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
    Get-Process $name
}

function head {
    param($Path, $n = 10)
    Get-Content $Path -Head $n
}

function tail {
    param($Path, $n = 10, [switch]$f = $false)
    Get-Content $Path -Tail $n -Wait:$f
}

# Does the the rough equivalent of dir /s /b. For example, dirs *.png is dir /s /b *.png
function dirs {
    if ($args.Count -gt 0) {
        Get-ChildItem -Recurse -Include "$args" | Foreach-Object FullName
    } else {
        Get-ChildItem -Recurse | Foreach-Object FullName
    }
}

# Useful shortcuts for traversing directories
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function ..... { Set-Location ..\..\..\.. }

# Compute file hashes - useful for checking successful downloads
function md5 { Get-FileHash -Algorithm MD5 $args }
function sha1 { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }

# Quick shortcut to start notepad
function n { notepad $args }

# Quick File Creation
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

# Directory Management
function mkcd {
    param($dir)
    New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue
    Set-Location $dir
}

### Quality of Life Aliases

# Navigation Shortcuts
function docs { Set-Location -Path $HOME\Documents }

function dtop { Set-Location -Path $HOME\Desktop }

# Quick Access to Editing the Profile
function ep { vim $PROFILE }

# Simplified Process Management
function k9 { Stop-Process -Name $args[0] }

# Enhanced Listing
function la { Get-ChildItem -Path . -Force | Format-Table -AutoSize }
function ll { Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize }

# Git Shortcuts
function gs { git status }

function ga { git add . }

function gc { param($m) git commit -m "$m" }

function gp { git push }

function gcom {
    git add .
    git commit -m "$args"
}
function lazyg {
    git add .
    git commit -m "$args"
    git push
}

# Quick Access to System Information
function sysinfo { Get-ComputerInfo }

# Networking Utilities
function flushdns { Clear-DnsClientCache }

# Clipboard Utilities
function cpy { Set-Clipboard $args[0] }

function pst { Get-Clipboard }

function mkdir {
    If ($args.Count -eq 0) {
        Write-Host "Usage: mkdir <directory1> [<directory2> ...]"
    } Else {
        foreach ($folder in $args) {
            If (-not(Test-Path -Path $folder)) {
                New-Item -ItemType Directory -Path $folder
            } Else {
                Write-Host "Directory '$folder' already exists"
            }
        }
    }
}

function rmdir {
    If ($args.Count -eq 0) {
        Write-Host "Usage: rmdir <directory1> [<directory2> ...]"
    } Else {
        foreach ($folder in $args) {
            If (Test-Path -Path $folder) {
                Remove-Item -Path $folder -Recurse -Force
            } Else {
                Write-Host "Directory '$folder' does not exist"
            }
        }
    }
}

# Execute cmd commands within powershell by prefixing cmd
function cmd() {
    cmd.exe /c "$args"
}

function winutil() {
    Invoke-RestMethod "https://christitus.com/win" | Invoke-Expression
}

function Grant-AdminAccess {
    param (
        [switch]$yes
    )
    if ($yes) {
        Get-LocalUser -Name "Administrator" | Enable-LocalUser
    } else {
        Get-LocalUser -Name "Administrator" | Disable-LocalUser
    }
}

function pathfetch {
    $profilePath = "$env:userprofile\Documents"

    if (Test-Path (Join-Path $profilePath "PowerShell")) {
        return "$profilePath\PowerShell"
    } elseif (Test-Path (Join-Path $profilePath "WindowsPowerShell")) {
        return "$profilePath\WindowsPowerShell"
    } else {
        Write-Output "Unknown PowerShell version or profile path"
    }
}

# Vanguard Anti-Cheat Controller
function vanguard($operation) {
    $fullPath = pathfetch
    try {
        Invoke-Expression "$fullPath\Modules\vanguard.ps1 -operation $operation"
    } catch {
        $install_vanguard_controller = Read-Host -Prompt "Rootkit controller script not found. Install? (y/n) Default (y)"
        if (-not ($install_vanguard_controller -eq "n")) {
            Invoke-RestMethod "https://github.com/pixincreate/configs/raw/main/windows/powershell/modules/vanguard.ps1" -OutFile "$fullPath\Modules\vanguard.ps1" | Invoke-Expression
        }
    }
}

function vanguard_scheduler($action) {
    $fullPath = pathfetch
    try {
        Invoke-Expression "$fullPath\Modules\vanguard_scheduler.ps1 -action $action"
    } catch {
        $install_vanguard_controller = Read-Host -Prompt "Vanguard scheduler script not found. Install? (y/n) Default (y)"
        if (-not ($install_vanguard_controller -eq "n")) {
            Invoke-RestMethod "https://github.com/pixincreate/configs/raw/main/windows/powershell/modules/vanguard_scheduler.ps1" -OutFile "$fullPath\Modules\vanguard_scheduler.ps1" | Invoke-Expression
        }
    }
}

# Enhanced PowerShell Experience
Set-PSReadLineOption -Colors @{
    Command   = 'Yellow'
    Parameter = 'Green'
    String    = 'DarkCyan'
}

# Invoke
Set-Alias -Name sudo -Value Grant-AdminAccess

# Check if the script is being run interactively
if ($Host.Name -eq 'ConsoleHost') {
    Update-Profile
}

# Invoke Expressions
Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })
Invoke-Expression "$(direnv hook pwsh)"
