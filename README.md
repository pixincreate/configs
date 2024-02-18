# Configs

This repo contains all of my development configs. I never had a backup of these before and hence this repo.

## Contents

```t
.
├── home
│   └── Code
│       └── User
│           └── settings.json                             # my vs_code settings
├── LICENSE
├── README.md                                             # this file
├── unix
│   └── dotfiles.sh                                       # automated environment setup that targets linux, android and mac
└── windows
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
    ├── theme
    │   └── pix-dynamc-theme.deskthemepack                # my desktop theme with added wallpaper
    └── winutil                                           # this folder is mostly redundant as it is already baked in powershell_profile
        ├── build.ps1                                     # executable builder script
        ├── windows.ico                                   # windows icon
        ├── winutil.exe                                   # winutil
        └── winutil.ps1                                   # winutil powershell script
```

## One line installer

```pwsh
irm "https://github.com/pixincreate/configs/raw/main/windows/powershell/setup.ps1" | iex
```

```sh
sudo apt-get update && sudo apt-get install -y curl git wget zsh && \
    curl -sSL https://github.com/pixincreate/configs/raw/main/unix/dotfiles.sh | bash
```

## Credits

- SanchithHegde for [dotfiles](https://github.com/SanchithHegde/dotfiles)
- Chris Titus for [powershell-profile](https://gthub.com/ChrisTitusTech/powershell-profile) and [winutil](https://gthub.com/ChrisTitusTech/winutil)
- Mike Battista for [Powershell - WSL Interop](https://github.com/mikebattista/PowerShell-WSL-Interop)
