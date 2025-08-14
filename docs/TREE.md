# Tree Structure of the Repository

```txt
.
├── .envrc
├── .github
│   └── workflows
│       └── ci.yml
├── .gitignore
├── .gitmodules
├── docs
│   ├── FEDORA_SETUP_GUIDE.md
│   ├── TREE.md
│   └── vanguard.md
├── home
│   ├── Code
│   │   └── .config
│   │       └── Code
│   │           └── User
│   ├── config
│   │   └── .config
│   │       ├── alacritty
│   │       ├── ghostty
│   │       ├── gitconfig
│   │       │   └── .gitconfig
│   │       ├── micro
│   │       │   ├── backups
│   │       │   ├── buffers
│   │       │   │   └── history
│   │       │   └── settings.json
│   │       ├── nvim
│   │       ├── starship.toml
│   │       ├── tmux
│   │       │   ├── plugins
│   │       │   │   └── tpm
│   │       │   └── tmux.conf
│   │       ├── topgrade.toml
│   │       ├── wezterm
│   │       ├── wt
│   │       │   └── LocalState
│   │       │       └── settings.json
│   │       └── zed
│   │           ├── .gitignore
│   │           ├── keymap.json
│   │           ├── settings.json
│   │           └── tasks.json
│   ├── git
│   │   └── .gitconfig
│   ├── ssh
│   │   └── .ssh
│   │       └── config
│   ├── vscode
│   │   └── .config
│   │       └── Code
│   │           └── User
│   │               └── settings.json
│   ├── Wallpaper
│   │   ├── PiXWallpaper
│   │   │   ├── pix-wallpaper-desktop.png
│   │   │   └── pix-wallpaper-mobile.png
│   │   └── Wallpaper
│   └── zsh
│       ├── .zsh
│       │   ├── .p10k.zsh
│       │   ├── .starship.zsh
│       │   ├── .zshenv
│       │   └── .zshrc
│       └── .zshenv
├── LICENSE
├── README.md
├── unix
│   ├── fedora
│   │   └── health-check.sh
│   ├── packages.toml
│   └── setup.py
└── windows
    ├── powershell
    │   ├── gp_backup.ps1
    │   ├── Microsoft.PowerShell_profile.ps1
    │   ├── modules
    │   │   ├── vanguard_scheduler.ps1
    │   │   └── vanguard.ps1
    │   └── setup.ps1
    ├── pro_scripts
    │   ├── bypassnro.bat
    │   ├── ms-account-check.bat
    │   ├── policies-enabler.ps1
    │   ├── reset-windows-update-component.bat
    │   └── wufix.bat
    ├── registry_edits
    │   ├── device-guard
    │   │   ├── down.reg
    │   │   └── up.reg
    │   └── folders-to-ThisPC
    │       ├── down.reg
    │       └── up.reg
    ├── theme
    │   └── pix-dynamc-theme.deskthemepack
    └── tools
        ├── ofgb
        │   └── placeholder
        └── winutil
            ├── build.ps1
            ├── windows.ico
            ├── winutil.exe
            └── winutil.ps1

```

tree generated with `tree -a -I ".git|fonts|themes|lua" . | pbcopy`
