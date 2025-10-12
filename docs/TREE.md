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
│   ├── TREE.md
│   └── vanguard.md
├── home
│   ├── cargo
│   │   └── .cargo
│   │       └── config.toml
│   ├── config
│   │   └── .config
│   │       ├── alacritty
│   │       │   ├── alacritty.toml
│   │       ├── Code
│   │       │   └── User
│   │       │       └── settings.json
│   │       ├── ghostty
│   │       ├── gitconfig
│   │       │   └── .gitconfig
│   │       ├── micro
│   │       │   ├── backups
│   │       │   ├── buffers
│   │       │   │   └── history
│   │       │   └── settings.json
│   │       ├── nvim
│   │       ├── starship
│   │       │   └── presets
│   │       │       ├── catppuccin-powerline.toml
│   │       │       ├── catppuccin.toml
│   │       │       ├── current_preset
│   │       │       ├── p10k.toml
│   │       │       └── starship.toml
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
│   ├── local
│   │   └── .local
│   │       └── bin
│   │           └── asus-profile-notify.sh
│   ├── Pictures
│   │   └── Pictures
│   │       └── Wallpapers
│   ├── ssh
│   │   └── .ssh
│   │       └── config
│   └── zsh
│       ├── .zsh
│       │   ├── .p10k.zsh
│       │   ├── .starship.sh
│       │   ├── .zshenv
│       │   └── .zshrc
│       └── .zshenv
├── LICENSE
├── README.md
├── unix
│   ├── common
│   │   ├── config
│   │   │   ├── git.sh
│   │   │   ├── nextdns.sh
│   │   │   └── rust.sh
│   │   ├── dotfiles
│   │   │   ├── directories.sh
│   │   │   ├── fonts.sh
│   │   │   ├── stow.sh
│   │   │   └── zsh.sh
│   │   └── helpers
│   │       └── platform.sh
│   ├── fedora
│   │   ├── bin
│   │   │   ├── omaforge-launch-browser
│   │   │   ├── omaforge-launch-webapp
│   │   │   ├── omaforge-pkg-manage
│   │   │   ├── omaforge-webapp-install
│   │   │   └── omaforge-webapp-remove
│   │   ├── config.json
│   │   ├── fedora-setup
│   │   ├── health-check.sh
│   │   ├── install
│   │   │   ├── config
│   │   │   │   ├── all.sh
│   │   │   │   ├── appimage.sh
│   │   │   │   ├── firmware.sh
│   │   │   │   ├── git.sh
│   │   │   │   ├── hardware
│   │   │   │   │   ├── all.sh
│   │   │   │   │   ├── asus.sh
│   │   │   │   │   └── nvidia.sh
│   │   │   │   ├── multimedia.sh
│   │   │   │   ├── nextdns.sh
│   │   │   │   ├── performance.sh
│   │   │   │   ├── secureboot.sh
│   │   │   │   ├── services.sh
│   │   │   │   └── system.sh
│   │   │   ├── dotfiles
│   │   │   │   ├── all.sh
│   │   │   │   ├── directories.sh
│   │   │   │   ├── fonts.sh
│   │   │   │   ├── stow.sh
│   │   │   │   └── zsh.sh
│   │   │   ├── helpers
│   │   │   │   ├── all.sh
│   │   │   │   ├── common.sh
│   │   │   │   ├── logging.sh
│   │   │   │   └── presentation.sh
│   │   │   ├── packaging
│   │   │   │   ├── all.sh
│   │   │   │   ├── base.sh
│   │   │   │   ├── bloatware.sh
│   │   │   │   ├── flatpak.sh
│   │   │   │   ├── rust.sh
│   │   │   │   └── webapps.sh
│   │   │   ├── post-install
│   │   │   │   ├── all.sh
│   │   │   │   └── finished.sh
│   │   │   ├── preflight
│   │   │   │   ├── all.sh
│   │   │   │   └── guard.sh
│   │   │   └── repositories
│   │   │       ├── all.sh
│   │   │       ├── copr.sh
│   │   │       ├── external.sh
│   │   │       ├── rpmfusion.sh
│   │   │       └── terra.sh
│   │   ├── packages
│   │   │   ├── base.packages
│   │   │   ├── bloatware.packages
│   │   │   ├── development.packages
│   │   │   ├── flatpak.packages
│   │   │   ├── system.packages
│   │   │   └── tools.packages
│   │   └── README.md
│   ├── macos
│   │   ├── bin
│   │   │   └── omaforge-pkg-manage
│   │   ├── config.json
│   │   ├── install
│   │   │   ├── config
│   │   │   │   ├── all.sh
│   │   │   │   ├── git.sh
│   │   │   │   ├── nextdns.sh
│   │   │   │   └── system.sh
│   │   │   ├── dotfiles
│   │   │   │   ├── all.sh
│   │   │   │   ├── directories.sh
│   │   │   │   ├── fonts.sh
│   │   │   │   ├── stow.sh
│   │   │   │   └── zsh.sh
│   │   │   ├── helpers
│   │   │   │   ├── all.sh
│   │   │   │   ├── common.sh
│   │   │   │   └── logging.sh
│   │   │   ├── packaging
│   │   │   │   ├── all.sh
│   │   │   │   ├── brew.sh
│   │   │   │   ├── cask.sh
│   │   │   │   ├── homebrew.sh
│   │   │   │   └── rust.sh
│   │   │   ├── post-install
│   │   │   │   ├── all.sh
│   │   │   │   └── finished.sh
│   │   │   └── preflight
│   │   │       ├── all.sh
│   │   │       └── guard.sh
│   │   ├── macos-setup
│   │   ├── packages
│   │   │   ├── brew.packages
│   │   │   └── cask.packages
│   │   └── README.md
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

tree generated with `tree -a -I ".git|fonts|themes|lua|*.jpg|*.png|*.webp|*.jpeg|*.gif|.DS_Store" . | pbcopy`
