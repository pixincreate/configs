# Configs

This repo contains all of my development configs. I never had a backup of these before and hence this repo.

## Contents

- VSCode profile: `settings.json`
- Extras:
  - GPEdit and HyperV enabler _(Run in admin mode)_
  - Winutil -- _This is not updated_
- Registry Edits
- Desktop Theme
- Unixified Powershell Profile with Packages
- Configs for Micro and Windows Terminal
- Dotfiles for Unix based systems (targets WSL2, Mac and Linux)

## Powershell for better life (Admin / sudo recommended)

### One line powershell profile installer

```pwsh
irm "https://github.com/pixincreate/configs/raw/main/powershell/setup.ps1" | iex
```

**Note:** Copy `settings.json` from `./wt/LocalState` dir to `C:\Users\<user>\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState`
