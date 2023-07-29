# Configs

This repo contains all of my development configs. I never had a backup of these before and hence this repo.

## Contents

- starship.toml: Tokyo-Night theme
- VSCode profile: Tokyo-Night theme with the extensions that I use
- Unixified powershell profile
- Extras: GPEdit and HyperV enabler (Run in admin mode)

## Powershell for better life (Admin / sudo recommended)

### One line powershell profile installer

```pwsh
irm "https://github.com/pixincreate/configs/raw/main/pwsh_profile.ps1" | iex
```

### Winutil

```pwsh
irm https://christitus.com/win | iex
```

#### Installation

In Powershell, execute:

```pwsh
echo "irm https://christitus.com/win | iex" > source.ps1
Install-Module -Name ps2exe -RequiredVersion 1.0.4 
2exe .\source.ps1 .\winutil.exe
```

Put the `winutil.exe` in a place where you wish the file to be and copy-paste its path in environment variables.

#### Usage

Open `terminal / cmd / powershell`, execute `winutil` to run the application
