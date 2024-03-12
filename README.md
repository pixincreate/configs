# Configs

This repo contains all of my development configs. I never had a backup of these before and hence this repo.

## Contents

```t
.
├── LICENSE                                               # LICENSE file for this repo
├── README.md                                             # this file
├── home
│   ├── .config
│   │   ├── micro
│   │   │   └── settings.json                             # configs for micro editor
│   │   └── wt
│   │       └── LocalState
│   │           └── settings.json                         # windows terminal settings
│   ├── .gitconfig                                        # my git config
│   ├── .ssh
│   │   └── config                                        # my ssh config
│   └── Code
│       └── User
│           └── settings.json                             # my vs_code settings
├── unix
│   ├── .zsh
│   │   ├── .zshenv                                       # zsh environment file
│   │   └── .zshrc                                        # zsh run commands file
│   ├── .zshenv                                           # zsh environment file that exposes.zsh directory
│   └── dotfiles.sh                                       # automated environment setup that targets linux, android and mac
└── windows
    ├── Winutil
    │   ├── build.ps1                                     # executable builder script
    │   ├── windows.ico                                   # windows icon
    │   ├── winutil.exe                                   # winutil
    │   └── winutil.ps1                                   # winutil powershell script
    ├── powershell
    │   ├── Microsoft.PowerShell_profile.ps1              # my powershell_profile configuration
    │   ├── modules
    │   │   ├── file_copy.ps1                             # a function to copy contents, especially terminal configs
    │   │   └── wsl_install.cmd                           # This file is automatically run on restart to install Debian, deleted once installed
    │   └── setup.ps1                                     # automated environment setup that targets windows
    ├── pro_scripts
    │   ├── gpedit-enabler.bat                            # enables group policy editor in windows_home
    │   └── hyper-v-enabler.bat                           # enables hyper-v in windows_home
    ├── registry_edits
    │   └── folders-to-ThisPC
    │       ├── add-folders-to-ThisPC.reg                 # this registry adds the good old folders at the top of `ThisPC`
    │       └── remove-folders-from-ThisPC.reg            # removes them
    └── theme
        └── pix-dynamc-theme.deskthemepack                # my desktop theme with added wallpaper
```

## One line installer

### If you're using a Windows PC, execute below command in [powershell](https://github.com/PowerShell/PowerShell)

```pwsh
irm "https://github.com/pixincreate/configs/raw/main/windows/powershell/setup.ps1" | iex
```

#### If you're using unix based OS, execute below in terminal (kitty, alacritty, iterm2 or any other terminal except the default one)

By unix based OS I mean, WSL, Debian, Arch, or macOS

```sh
sudo apt-get update && sudo apt-get install -y curl git wget zsh && \
    curl -sSL https://github.com/pixincreate/configs/raw/main/unix/dotfiles.sh | bash
```

> [!NOTE]
> Both the commands are completely different not only in nature but also in the job they do here. More info below.

## Job done by commands

### Shell command

- Executes `unix/dotfiles.sh`
- Depending on the OS type: (`Andoroid`, `Linux based OS`, `macOS`), below mentioned packages are installed:
  - android-tools
  - croc
  - direnv
  - git
  - git-delta
  - micro
  - neofetch
  - neovim
  - openssh
  - sqlite
  - starship
  - tar (Android only)
  - tree
  - tsu (Android only)
  - termux-am (Android only)
  - walk
  - zoxide
- `Rish` is setup for Android as well
- Installs `starship` and `zgenom` plugin manager
- Restores VSCode settings
- Setup `zshell` where all `zsh` specific is kept in a single directory named as `.zsh`
- Micro, SSH, Code settings are restored along with `.gitconfig`
- In the end, after all the setup is done, the cloned repo is deleted

### Powershell command

- Executes `setup.ps1`
- Installs `Fira Code` font
- Installs below mentioned packages:
  - delta
  - git
  - gsudo
  - starship
  - zoxide
  - micro
  - direnv
  - walk
  - Restores windows terminal settings
  - Installs `starship`
  - Installs WSL-Interop
  - Restores `powershell_profile` where there exist many functions that help replicate linux commands and functionality
  - Restores VSCode settings
  - Disables powershell telemetry
  - It also has some extras
    - GPEdit enabler
    - Hyper-V enabler
    - Registry to add / remove default folders in `ThisPC` (downloads, documents, desktop, etc.,)
  - Installs WSL

## Credits

- SanchithHegde for [dotfiles](https://github.com/SanchithHegde/dotfiles)
- Chris Titus for [powershell-profile](https://github.com/ChrisTitusTech/powershell-profile) and [winutil](https://github.com/ChrisTitusTech/winutil)
- Mike Battista for [Powershell - WSL Interop](https://github.com/mikebattista/PowerShell-WSL-Interop)
