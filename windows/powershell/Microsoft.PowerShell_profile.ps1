# Initial GitHub.com connectivity check with 1 second timeout
$checkConnectivity = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

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

    if (-not $global:checkConnectivity) {
        Write-Host "Update check failed due to GitHub not responding within 1 second." -ForegroundColor Yellow
        return
    }

    try {
        $profileUpdated = $false
        $url = "https://github.com/pixincreate/configs/raw/main/windows/powershell/Microsoft.PowerShell_profile.ps1"

        $profilePaths = @()
        if ($PSVersionTable.PSEdition -eq "Core") {
            $profilePaths += "$env:userprofile\Documents\PowerShell"
            $profilePaths += "$env:userprofile\Documents\WindowsPowerShell"
        } elseif ($PSVersionTable.PSEdition -eq "Desktop") {
            $profilePaths += "$env:userprofile\Documents\WindowsPowerShell"
        }

        foreach ($profilePath in $profilePaths) {
            $profileFile = Join-Path $profilePath "Microsoft.Powershell_profile.ps1"
            $oldHash = Get-ValidatedFileHash -filePath $profileFile

            $newFileName = $(Split-Path -Leaf $url)
            Invoke-RestMethod $url -OutFile "$env:temp/$newFileName"
            $newHash = Get-FileHash "$env:temp/$newFileName"

            if ($newHash.Hash -ne $oldHash.Hash) {
                Copy-Item -Path "$env:temp/$newFileName" -Destination $oldHash.Path -Force

                if ($profileFile -eq $PROFILE) {
                    Copy-Item -Path $PROFILE -Destination "$profilePath\Microsoft.VSCode_profile.ps1" -Force
                }
                Write-Host -NoNewLine "`rPlease restart your shell to reflect changes".PadRight(100, " ") -ForegroundColor Magenta
                $profileUpdated = $true
            }
        }

        if (-not $profileUpdated) {
            Write-Host "`rProfile is up to date!".PadRight(100, " ") -ForegroundColor Green
        }
    } catch {
        Write-Error "Update check failed due to: $_"
        Write-Host "Try elevating with 'sudo' and running 'Update-Profile' to force an update." -ForegroundColor Yellow
    } finally {
        Remove-Item -Path "$env:temp/*.ps1" -ErrorAction SilentlyContinue
    }
}

Update-Profile

# Admin Check and Prompt Customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# Admin Utils
function Grant-AdminAccess {
    if (-not $isAdmin) {
        if ($args.Count -gt 0) {
            $argList = "& '$args'"
            Start-Process wt -Verb runAs -ArgumentList "PowerShell -NoExit -Command $argList"
        } else {
            Start-Process wt -Verb runAs
        }
    }
}
# Set UNIX-like aliases for the admin command, so sudo <command> will run the command with elevated rights.
Set-Alias -Name su -Value Grant-AdminAccess

### Editor Configuration

# Check for existence of command
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

$EDITOR = if (Test-CommandExists nvim) { 'nvim' }
          elseif (Test-CommandExists pvim) { 'pvim' }
          elseif (Test-CommandExists vim) { 'vim' }
          elseif (Test-CommandExists vi) { 'vi' }
          elseif (Test-CommandExists code) { 'code' }
          elseif (Test-CommandExists code-insiders) { 'code' }
          elseif (Test-CommandExists notepad++) { 'notepad++' }
          elseif (Test-CommandExists sublime_text) { 'sublime_text' }
          else { 'notepad' }

Set-Alias -Name vi -Value $EDITOR

# Utility Functions

function Edit-Profile {
    vim $PROFILE.CurrentUserAllHosts
}

function Clear-Cache {
    # add clear cache logic here
    Write-Host "Clearing cache..." -ForegroundColor Cyan

    # Clear Windows Prefetch
    Write-Host "Clearing Windows Prefetch..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

    # Clear Windows Temp
    Write-Host "Clearing Windows Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Clear User Temp
    Write-Host "Clearing User Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Clear Internet Explorer Cache
    Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Yellow
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Cache clearing completed." -ForegroundColor Green
}

# Quick Access to System Information
function sysinfo { Get-ComputerInfo }

# Networking Utilities
function flushdns {
	Clear-DnsClientCache
	Write-Host "DNS has been flushed!"
}

# Clipboard Utilities
function cpy { Set-Clipboard $args[0] }

function pst { Get-Clipboard }

# Execute cmd commands within powershell by prefixing cmd
function cmd() {
    cmd.exe /c "$args"
}

# Start WinUtil; Requires Elevation
function winutil() {
    Invoke-RestMethod "https://christitus.com/win" | Invoke-Expression
}

function Update-Applications {
    winget update --all --accept-source-agreements --accept-package-agreements --source winget
}
Set-Alias -Name winup -Value Update-Applications

function Export-Installed {
    $installedItems = winget list
    $fileName = Read-Host "Enter the file name with extension (e.g., All Intstalled Items.txt)"
    $installedItems | Out-File -FilePath $fileName
    Write-Host "The list has been saved to $fileName"
}

# Reload the powershell profile
function reload {
    & $PROFILE
}

### Unix like commands

function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Format-Table -HideTableHeaders
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

function touch($file) { "" | Out-File $file -Encoding ASCII }

# find-file
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
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
    set-item -force -path "env:$name" -value $value;
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

# Fucntion to show show hidden folders like .git
function ls-hidden {
    Get-ChildItem -Force | Where-Object { $_.Attributes -match 'Hidden' }
}

# Function to hide specific files or folders or all items in the current directory
function hide {
    param (
        [string]$name = ""
    )

    if (-not [string]::IsNullOrEmpty($name)) {
        # Hide specific file or folder
        $itemPath = Join-Path -Path (Get-Location) -ChildPath $name
        $item = Get-Item -Path $itemPath -ErrorAction SilentlyContinue
        if ($item) {
            # Apply attributes to hide
            attrib +h +s +r +x $item.FullName
            Write-Host "Hidden: $name"
        } else {
            Write-Host "Item not found: $name"
        }
    } else {
        # Hide all files and folders in the current directory
        Get-ChildItem -Force | ForEach-Object {
            attrib +h +s +r +x $_.FullName
        }
        Write-Host "All items in the current directory are now hidden."
    }
}

# Function to unhide specific files or folders or all items in the current directory
function unhide {
    param (
        [string]$name = ""
    )

    if (-not [string]::IsNullOrEmpty($name)) {
        # Unhide specific file or folder by searching for hidden items
        $itemPath = Join-Path -Path (Get-Location) -ChildPath $name
        $item = Get-ChildItem -Path (Get-Location) -Filter $name -Force -ErrorAction SilentlyContinue
        if ($item) {
            # Remove attributes to unhide
            foreach ($i in $item) {
                attrib -h -s -r -x $i.FullName
                Write-Host "Unhidden: $($i.Name)"
            }
        } else {
            Write-Host "Item not found: $name"
        }
    } else {
        # Unhide all files and folders in the current directory
        Get-ChildItem -Force | ForEach-Object {
            attrib -h -s -r -x $_.FullName
        }
        Write-Host "All items in the current directory are now unhidden."
    }
}

# Function to add a file or folder in the current directory
function add {
    param($Name)

    # Check if the name contains an extension
    if ($Name -like "*.*") {
        # Create a file
        New-Item -ItemType File -Path (Join-Path -Path (Get-Location) -ChildPath $Name) -Force
    } else {
        # Create a folder
        New-Item -ItemType Directory -Path (Join-Path -Path (Get-Location) -ChildPath $Name) -Force
    }
}

# Function to delete a file or folder in the current directory
function del {
    param($Name)

    # Combine path with current directory
    $Path = Join-Path -Path (Get-Location) -ChildPath $Name

    # Remove the item if it exists
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
    } else {
        Write-Host "Item '$Name' not found in the current directory."
    }
}

# Function to move a file or folder to a destination
function move {
    param(
        [string]$Name,
        [string]$Destination
    )

    # Combine path with current directory
    $Path = Join-Path -Path (Get-Location) -ChildPath $Name

    # Move the item if it exists
    if (Test-Path $Path) {
        Move-Item -Path $Path -Destination $Destination -Force
    } else {
        Write-Host "Item '$Name' not found in the current directory."
    }
}

### Shortcut Aliases

# Useful shortcuts for traversing directories
function .. { Set-Location ..\ }
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
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

# Navigation Shortcuts
function docs { Set-Location -Path $HOME\Documents }

function dtop { Set-Location -Path $HOME\Desktop }

# Quick Access to Editing the Profile
function ep { vim $PROFILE }

# Simplified Process Management
function k9 { Stop-Process -Name $args[0] }

### Git Shortcuts

# Current branch name
function current_branch { git rev-parse --abbrev-ref HEAD }

# Check for main or develop branches
function git_main_branch {
    if (git show-ref --verify --quiet "refs/heads/main") {
        return "main"
    } elseif (git show-ref --verify --quiet "refs/heads/trunk") {
        return "trunk"
    } elseif (git show-ref --verify --quiet "refs/heads/master") {
        return "master"
    } elseif (git show-ref --verify --quiet "refs/heads/develop") {
        return "develop"
    }
    return "master"
}

function git_develop_branch {
    if (git show-ref --verify --quiet "refs/heads/develop") {
        return "develop"
    } elseif (git show-ref --verify --quiet "refs/heads/development") {
        return "development"
    } elseif (git show-ref --verify --quiet "refs/heads/dev") {
        return "dev"
    } elseif (git show-ref --verify --quiet "refs/heads/devel") {
        return "devel"
    }
    return "develop"
}

function gs { git status }

function ga { git add $args }

function gaa { git add --all }

function gapa { git add --patch }

function gau { git add --update }

function gav { git add --verbose }

function gcmsg { param($m) git commit -m "$m" }

function gcm { git checkout (git_main_branch) }

function gcl { git clone $args }

# PowerShell points `gp` to Get-ItemProperty by default, we're changing that
Remove-Item -Force Alias:gp -ErrorAction SilentlyContinue
Set-Alias gip Get-ItemProperty
function gp { git push }

function gco { git checkout $args }

function gcb { param($name) git checkout -b $name }

function ggg { git gui citool }

function gr { git rebase $args }

function ggp {
    if ($args.Count -eq 0) {
        $branch = current_branch
        git push origin $branch
    } else {
        git push origin $args
    }
}

function ggl {
    if ($args.Count -eq 0) {
        $branch = current_branch
        git pull origin $branch
    } else {
        git pull origin $args
    }
}

function gcam { git commit -a -m "$args" }

function gca { git commit --verbose --all -m "$args" }

function gcn { git commit --no-edit -m "$args" }

function gsta { git stash push }

function gstp { git stash pop }

function gstl { git stash list }

function gsd { git stash drop }

function gclean { git clean --interactive -d }

function gb { git branch }

function gba { git branch --all }

function gbd { git branch -d $args }

function gbD { git branch -D $args }

function gbda { git branch --no-color --merged | Where-Object { $_ -notmatch "^(\\*|$(git_main_branch)|$(git_develop_branch))$" } | ForEach-Object { git branch -d $_ } }

function gunwip { git rev-list --max-count=1 --format="%s" HEAD | Select-String --Pattern "--wip--" | If ($?) { git reset HEAD~1 } }

function gpr { git pull --rebase }

function gpf { git push --force $args }

function gfg { git ls-files | Select-String $args }

function gtags { git tag --sort=-v:refname -n --list "$args*" }

function gtc { git tag | Sort-Object }

function gfd { git fetch }

function gfo { git fetch origin }

function gfa { git fetch --all --tags --prune }

function ggd { git log --graph --oneline --decorate }

function glg { git log --graph --stat }

function glola { git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all }

function ghs { git reset --hard }

function grh { git reset --hard }

function gpv { git push --verbose }

function gpf! { git push --force }

function gpristine { git reset --hard; git clean --force -dfx }

function gl { git pull }

function gm { git merge }

function gmff { git merge --ff-only }

function gmum { git merge upstream/$(git_main_branch) }

function gmom { git merge origin/$(git_main_branch) }

function gml { git merge --abort }

function gmc { git merge --continue }

function gms { git merge --squash }

function gpru { git pull upstream $(git_main_branch) }

function gpru! { git pull upstream $(git_main_branch) }

function gpush { git push origin $(git_main_branch) }

function glg! { git log --graph --oneline --decorate --all }

function grs { git restore $args }

function grss { git restore --source $args }

function grst { git restore --staged $args }

function gmtl { git mergetool --no-prompt }

function gmtlvim { git mergetool --no-prompt --tool=vimdiff }

function gtf { git tag -a "$args" -m "$args" }

function gtv { git tag | Sort-Object }

function gignore { git update-index --assume-unchanged $args }

function gunignore { git update-index --no-assume-unchanged $args }

function gwt { git worktree }

function gwtls { git worktree list }

function gwtmv { git worktree move $args }

function gwtrm { git worktree remove $args }

function gsub { git submodule update --init }

function gsubup { git submodule update --remote }

function gsu { git submodule update }

function gsi { git submodule init }

function gsdn { git svn dcommit }

function gsr { git svn rebase }

function gsx { git svn fetch }

function gsxup { git svn rebase }

function gts { git tag -s $args }

function gtag { git tag $args }

function gtagg { git tag --list }

### Eza Aliases

function eza { eza @args }

# Basic directory listings
function l { eza }
function ll { eza -l }
function la { eza -a }
function lla { eza -la }
function lsd { eza --dirs-only }

# Color and formatting options
function lcolor { eza --color=always }
function lls { eza --long --sort=size }
function llt { eza --long --sort=time }

# Human-readable sizes
function lhr { eza -lh }

# Recursive listing
function lrec { eza -R }

# Detailed view including hidden files
function ld { eza -lah }

# Sort options
function lsort { eza --sort=$args }

# Filter options
function lgrep { eza | Select-String $args }

# View file details
function lview { eza -l $args }

# For checking disk usage
function du { eza --du @args }

# Custom command to show a tree view
function tree { eza --tree @args }

### VS Code (stable / insiders) / VSCodium PowerShell functions
# Original zsh Authors:
#   https://github.com/MarsiBarsi (original author)
#   https://github.com/babakks
#   https://github.com/SteelShot
#   https://github.com/AliSajid

# Determine the VS Code executable
if ($env:VSCODE -and -not (Get-Command $env:VSCODE -ErrorAction SilentlyContinue)) {
    Write-Host "'$($env:VSCODE)' flavour of VS Code not detected."
    Remove-Variable VSCODE -ErrorAction SilentlyContinue
}

if (-not $env:VSCODE) {
    if (Get-Command code -ErrorAction SilentlyContinue) {
        $env:VSCODE = 'code'
    } elseif (Get-Command code-insiders -ErrorAction SilentlyContinue) {
        $env:VSCODE = 'code-insiders'
    } elseif (Get-Command codium -ErrorAction SilentlyContinue) {
        $env:VSCODE = 'codium'
    } else {
        return
    }
}

function vsc {
    param (
        [string[]]$args
    )
    if ($args) {
        & $env:VSCODE @args
    } else {
        & $env:VSCODE .
    }
}

# Aliases
Set-Alias vsca "$env:VSCODE --add"
Set-Alias vscd "$env:VSCODE --diff"
Set-Alias vscg "$env:VSCODE --goto"
Set-Alias vscn "$env:VSCODE --new-window"
Set-Alias vscr "$env:VSCODE --reuse-window"
Set-Alias vscw "$env:VSCODE --wait"
Set-Alias vscu "$env:VSCODE --user-data-dir"
Set-Alias vscp "$env:VSCODE --profile"
Set-Alias vsced "$env:VSCODE --extensions-dir"
Set-Alias vscie "$env:VSCODE --install-extension"
Set-Alias vscue "$env:VSCODE --uninstall-extension"
Set-Alias vscv "$env:VSCODE --verbose"
Set-Alias vscl "$env:VSCODE --log"
Set-Alias vscde "$env:VSCODE --disable-extensions"

### fzf specific usecases
$env:FZF_DEFAULT_OPTS=@"
--layout=reverse
--cycle
--scroll-off=5
--border
--preview-window=right,60%,border-left
--bind ctrl-u:preview-half-page-up
--bind ctrl-d:preview-half-page-down
--bind ctrl-f:preview-page-down
--bind ctrl-b:preview-page-up
--bind ctrl-g:preview-top
--bind ctrl-h:preview-bottom
--bind alt-w:toggle-preview-wrap
--bind ctrl-e:toggle-preview
"@

function _fzf_open_path
{
  param (
    [Parameter(Mandatory=$true)]
    [string]$input_path
  )
  if ($input_path -match "^.*:\d+:.*$")
  {
    $input_path = ($input_path -split ":")[0]
  }
  if (-not (Test-Path $input_path))
  {
    return
  }
  $cmds = @{
    'bat' = { bat $input_path }
    'cat' = { Get-Content $input_path }
    'cd' = {
      if (Test-Path $input_path -PathType Leaf)
      {
        $input_path = Split-Path $input_path -Parent
      }
      Set-Location $input_path
    }
    'nvim' = { nvim $input_path }
    'remove' = { Remove-Item -Recurse -Force $input_path }
    'echo' = { Write-Output $input_path }
  }
  $cmd = $cmds.Keys | fzf --prompt 'Select command> '
  & $cmds[$cmd]
}

function _fzf_get_path_using_fd
{
  $input_path = fd --type file --follow --hidden --exclude .git |
    fzf --prompt 'Files> ' `
      --header-first `
      --header 'CTRL-S: Switch between Files/Directories' `
      --bind 'ctrl-s:transform:if not "%FZF_PROMPT%"=="Files> " (echo ^change-prompt^(Files^> ^)^+^reload^(fd --type file^)) else (echo ^change-prompt^(Directory^> ^)^+^reload^(fd --type directory^))' `
      --preview 'if "%FZF_PROMPT%"=="Files> " (bat --color=always {} --style=plain) else (eza -T --colour=always --icons=always {})'
  return $input_path
}

function _fzf_get_path_using_rg
{
  $INITIAL_QUERY = "${*:-}"
  $RG_PREFIX = "rg --column --line-number --no-heading --color=always --smart-case"
  $input_path = "" |
    fzf --ansi --disabled --query "$INITIAL_QUERY" `
      --bind "start:reload:$RG_PREFIX {q}" `
      --bind "change:reload:sleep 0.1 & $RG_PREFIX {q} || rem" `
      --bind 'ctrl-s:transform:if not "%FZF_PROMPT%" == "1. ripgrep> " (echo ^rebind^(change^)^+^change-prompt^(1. ripgrep^> ^)^+^disable-search^+^transform-query:echo ^{q^} ^> %TEMP%\rg-fzf-f ^& type %TEMP%\rg-fzf-r) else (echo ^unbind^(change^)^+^change-prompt^(2. fzf^> ^)^+^enable-search^+^transform-query:echo ^{q^} ^> %TEMP%\rg-fzf-r ^& type %TEMP%\rg-fzf-f)' `
      --color 'hl:-1:underline,hl+:-1:underline:reverse' `
      --delimiter ':' `
      --prompt '1. ripgrep> ' `
      --preview-label 'Preview' `
      --header 'CTRL-S: Switch between ripgrep/fzf' `
      --header-first `
      --preview 'bat --color=always {1} --highlight-line {2} --style=plain' `
      --preview-window 'up,60%,border-bottom,+{2}+3/3'
  return $input_path
}

function fdg
{
  _fzf_open_path $(_fzf_get_path_using_fd)
}

function rgg
{
  _fzf_open_path $(_fzf_get_path_using_rg)
}

### Vanguard Anti-Cheat Controller
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

# Scheduler setup
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

### Enhanced PowerShell Experience
# Enhanced PSReadLine Configuration
$PSReadLineOptions = @{
    ContinuationPrompt  = '  '
    EditMode = 'Windows'
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
    Colors = @{
        Command = '#87CEEB'  # SkyBlue (pastel)
        Parameter = '#98FB98'  # PaleGreen (pastel)
        Operator = '#FFB6C1'  # LightPink (pastel)
        Variable = '#DDA0DD'  # Plum (pastel)
        String = '#FFDAB9'  # PeachPuff (pastel)
        Number = '#B0E0E6'  # PowderBlue (pastel)
        Type = '#F0E68C'  # Khaki (pastel)
        Comment = '#D3D3D3'  # LightGray (pastel)
        Keyword = '#8367c7'  # Violet (pastel)
        Error = '#FF6347'  # Tomato
        Selection = $PSStyle.Background.Black
        InLinePrediction = $PSStyle.Foreground.BrightYellow + $PSStyle.Background.BrightBlack
    }
    PredictionSource = 'HistoryAndPlugin'
    PredictionViewStyle = 'ListView'
    MaximumHistoryCount = 9999999
    BellStyle = 'None'  # Consider changing to 'Sound' or 'Visual'
    AddToHistoryHandler = {
        param($line)
        $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
        $hasSensitive = $sensitive | Where-Object { $line -match [regex]::Escape($_) }
        return ($null -eq $hasSensitive)
    }
}
Set-PSReadLineOption @PSReadLineOptions

# Custom key handlers
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo
Set-PSReadLineKeyHandler -Chord 'Enter' -Function ValidateAndAcceptLine
Set-PSReadLineKeyHandler -Key "Ctrl+f" -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert("fdg")
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key "Ctrl+g" -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert("rgg")
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

# Custom completion for common commands
$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    $customCompletions = @{
        'git' = @('status', 'add', 'commit', 'push', 'pull', 'clone', 'checkout')
        'npm' = @('install', 'start', 'run', 'test', 'build')
        'cargo' = @('r', 'b', 'clippy', 'fmt')
    }

    $command = $commandAst.CommandElements[0].Value
    if ($customCompletions.ContainsKey($command)) {
        $customCompletions[$command] | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}
Register-ArgumentCompleter -Native -CommandName git, npm, cargo -ScriptBlock $scriptblock

function Invoke-Starship-TransientFunction {
  &starship module character
}

### Invoke Expressions
Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })
Invoke-Expression "$(direnv hook pwsh)"

# Enable Transient prompt in Starship
Enable-TransientPrompt

Set-Alias -Name z -Value __zoxide_z -Option AllScope -Scope Global -Force
