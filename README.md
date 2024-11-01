# Configs

This repo contains all of my development configs. I never had a backup of these before and hence this repo.

## Contents

```txt
.
├── .gitignore                                      # git ignore file
├── .gitmodules                                     # git submodules
├── LICENSE                                         # license for this repo
├── README.md                                       # this file
├── docs
│   └── vanguard.md                                 # vanguard controller documentation
├── home
│   ├── .config
│   │   ├── alacritty
│   │   │   └── alacritty.toml                      # my alacritty terminal settings
│   │   ├── micro
│   │   │   └── settings.json                       # my micro editor settings
│   │   ├── tmux
│   │   │   └── .tmux.conf                          # my tmux config
│   │   └── wt
│   │       └── LocalState
│   │           └── settings.json                   # my windows terminal settings
│   ├── .gitconfig
│   ├── .ssh
│   │   └── config                                  # my ssh config
│   └── Code
│       └── User
│           └── settings.json                       # my vs_code settings
├── unix
│   ├── .zsh
│   │   ├── .p10k.zsh                               # powerlevel10k zsh theme
│   │   ├── .zshenv                                 # zsh environment file
│   │   └── .zshrc                                  # zsh run commands file
│   ├── .zshenv                                     # zsh environment file that exposes.zsh directory
│   └── setup.sh                                    # automated environment setup that targets linux, android and mac
└── windows
    ├── powershell
    │   ├── Microsoft.PowerShell_profile.ps1        # my powershell_profile configuration
    │   ├── modules
    │   │   ├── file_copy.ps1                       # a function to copy contents, especially terminal configs
    │   │   ├── vanguard.ps1                        # a function to control vanguard execution
    │   │   ├── vanguard_scheduler.ps1              # a function to schedule the disabling vanguard execution
    │   │   └── wsl_install.cmd                     # this file is automatically run on restart to install Debian, deleted once installed
    │   └── setup.ps1                               # powershell setup script
    ├── pro_scripts
    │   ├── gpedit-enabler.bat                      # enables group policy editor in windows_home
    │   └── hyper-v-enabler.bat                     # enables hyper-v in windows_home
    ├── registry_edits
    │   └── folders-to-ThisPC
    │       ├── add-folders-to-ThisPC.reg           # registry to add default folders at the top of `ThisPC`
    │       └── remove-folders-from-ThisPC.reg      # registry to remove default folders from the top of `ThisPC`
    ├── theme
    │   └── pix-dynamc-theme.deskthemepack          # my desktop theme with added wallpaper
    └── tools
        ├── ofgb                                    # oh frick! go back! a tool to disable ads in windows, downloaded by setup.ps1
        │   └── placeholder
        └── winutil
            ├── build.ps1                           # winutil builder script
            ├── windows.ico                         # winutil icon
            ├── winutil.exe                         # winutil executable
            └── winutil.ps1                         # winutil powershell script

```

## One line installer

### If you're using a Windows PC, execute below command in [powershell](https://github.com/PowerShell/PowerShell)

If this is a fresh Windows installation, it is recommended to re-do the Windows installation with `MicroWin`:

1. Download the latest Windows 11 (recommended) ISO (international edition)
2. Open winutil (in elevated powershell, execute the following command: `irm "christitus.com/win" | iex`) and go to `MicroWin` tab
3. Follow the instructions (do not select any drivers or inject them)
4. Wait until ISO is created. Use `Rufus` to make a bootable drive
5. Re-do the installation by booting from USB (Change boot priority in `UEFI` menu)

```pwsh
irm "https://github.com/pixincreate/configs/raw/main/windows/powershell/setup.ps1" | iex
```

### If you're using unix based OS, execute below in terminal (kitty, alacritty, iterm2 or any other terminal except the default one)

Unix based OS here means, `WSL`, `Debian`, or `macOS`

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
> Both the commands are completely different not only in nature but also in the job they do here.
> The first command is for Windows and the second one is for unix based OS.

#### Vanguard Controller

To learn about what Vanguard controller is and how to use it, refer to [Vanguard Controller](./docs/vanguard.md)

## Credits

- SanchithHegde for [dotfiles](https://github.com/SanchithHegde/dotfiles)
- Chris Titus for [powershell-profile](https://github.com/ChrisTitusTech/powershell-profile), [bash-profile](https://github.com/ChrisTitusTech/mybash) and [winutil](https://github.com/ChrisTitusTech/winutil)
- Mike Battista for [Powershell - WSL Interop](https://github.com/mikebattista/PowerShell-WSL-Interop)
- AndrewMast for [disable_vanguard.vbs](https://gist.github.com/AndrewMast/742ac7e07c37096017e907b0fd8ec7bb?permalink_comment_id=4616472#gistcomment-4616472)
