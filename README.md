# Configs

This repo contains all of my development configs. I never had a backup of these before and hence this repo.

## Contents

```txt
.
├── home
│   ├── Code
│   │   └── User
│   │       └── settings.json                                       # my vs_code settings
│   ├── .config
│   │   ├── micro
│   │   │   └── settings.json                                       # configs for micro editor
│   │   ├── starship.toml                                           # my starship configs
│   │   └── wt
│   │       └── LocalState
│   │           └── settings.json                                   # my windows terminal settings
│   ├── .gitconfig                                                  # my git config
│   └── .ssh
│       └── config                                                  # my ssh config
├── LICENSE                                                         # license for this repo
├── README.md                                                       # this file
├── unix
│   ├── dotfiles_setup.sh                                           # automated environment setup that targets linux, android and mac
│   ├── .zsh
│   │   ├── .zshenv                                                 # zsh environment file
│   │   └── .zshrc                                                  # zsh run commands file
│   └── .zshenv                                                     # zsh environment file that exposes.zsh directory
└── windows
    ├── powershell
    │   ├── Microsoft.PowerShell_profile.ps1                        # my powershell_profile configuration
    │   ├── modules
    │   │   ├── file_copy.ps1                                       # a function to copy contents, especially terminal configs
    │   │   ├── vanguard.ps1                                        # a function to control vanguard execution
    │   │   ├── vanguard_scheduler.ps1                              # a function to schedule the disabling vanguard execution
    │   │   └── wsl_install.cmd                                     # this file is automatically run on restart to install Debian, deleted once installed
    │   └── setup.ps1
    ├── pro_scripts
    │   ├── gpedit-enabler.bat                                      # enables group policy editor in windows_home
    │   └── hyper-v-enabler.bat                                     # enables hyper-v in windows_home
    ├── registry_edits
    │   └── folders-to-ThisPC
    │       ├── add-folders-to-ThisPC.reg                           # registry to add default folders at the top of `ThisPC`
    │       └── remove-folders-from-ThisPC.reg                      # registry to remove default folders from the top of `ThisPC`
    ├── theme
    │   └── pix-dynamc-theme.deskthemepack                          # my desktop theme with added wallpaper
    └── tools
        ├── ofgb                                                    # oh frick! go back! a tool to disable ads in windows, downloaded by setup.ps1
        │   └── placeholder
        └── winutil
            ├── build.ps1                                           # winutil builder script
            ├── windows.ico
            ├── winutil.exe                                         # winutil executable
            └── winutil.ps1                                         # winutil powershell script

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
    bash -c "$(curl -sSL https://github.com/pixincreate/configs/raw/main/unix/setup.sh)" -- --setup
```

If running in Termux

```sh
pkg update && pkg upgrade -y && pkg install -y curl git wget zsh && \
    bash -c "$(curl -sSL https://github.com/pixincreate/configs/raw/main/unix/setup.sh)" -- --setup

```

> [!IMPORTANT]
> Both the commands are completely different not only in nature but also in the job they do here. More info below.

## Job done by the commands

### Shell command

- Executes `unix/dotfiles_setup.sh`
- Depending on the OS type: (`Android`, `Linux based OS`, `macOS`), below mentioned packages are installed:
  - android-tools
  - bat
  - binutils (Android only)
  - croc
  - direnv
  - docker
  - fastfetch
  - fzf
  - git
  - git-delta
  - micro
  - multitail
  - neovim
  - nextdns
  - node
  - openssh
  - rustup-init
  - sqlite
  - starship
  - tar (Android only)
  - topgrade
  - tree
  - tsu (Android only)
  - termux-am (Android only)
  - termux-api (Android only)
  - walk
  - xclip
  - zoxide
- `Rish` is setup for Android given that you've `Shizuku` installed and rish files are exported to `Documents/Dev/Shizuku` directory
- Installs `starship` and `zgenom` plugin manager
- Restores:
  - VSCode settings
  - .gitconfig
  - .ssh config
  - micro, windows terminal, and starship configs
- Setup `zshell` where all `zsh` specific is kept in a single directory named as `.zsh`
- In the end, after all the setup is done, the cloned repo is deleted

### Powershell command

- Executes `setup.ps1`
- Installs `Fira Code Nerd` font
- Installs below mentioned modules:
  - ps2exe
  - Terminal icons
  - wslInterop
- Installs below mentioned packages:
  - delta
  - direnv
  - fzf
  - git
  - gsudo
  - micro
  - neovim
  - powershell
  - rustup
  - starship
  - topgrade
  - vs build tools
  - walk
  - zoxide
- Disable all windows telemetry and ads with OFGB
- Sets up dev environment:
  - Restores windows terminal settings
  - Restores VSCode settings
  - Restores `powershell_profile` where there exist many functions that help replicate linux commands and functionality
    - Optionally, Vanguard controller and scheduler
  - Installs WSL

The repo also has additional scripts:

- GPEdit enabler
- Hyper-V enabler
- Registry to add / remove default folders in `ThisPC` (downloads, documents, desktop, etc.,)
- Winutil (package)

#### Vanguard Controller

To learn about what Vanguard controller is and how to use it, refer to [Vanguard Controller](./docs/vanguard.md)

## Credits

- SanchithHegde for [dotfiles](https://github.com/SanchithHegde/dotfiles)
- Chris Titus for [powershell-profile](https://github.com/ChrisTitusTech/powershell-profile), [bash-profile](https://github.com/ChrisTitusTech/mybash) and [winutil](https://github.com/ChrisTitusTech/winutil)
- Mike Battista for [Powershell - WSL Interop](https://github.com/mikebattista/PowerShell-WSL-Interop)
- AndrewMast for [disable_vanguard.vbs](https://gist.github.com/AndrewMast/742ac7e07c37096017e907b0fd8ec7bb?permalink_comment_id=4616472#gistcomment-4616472)
