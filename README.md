# Configs

This repo contains all of my development configs. I never had a backup of these before and hence this repo.

## Contents

Check repo [tree](./docs/TREE.md) to get list of file contents.

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

To learn about what Vanguard controller is and how to use it, refer to [Vanguard Controller](./docs/VANGUARD.md)

## Credits

- SanchithHegde for [dotfiles](https://github.com/SanchithHegde/dotfiles)
- Chris Titus for [powershell-profile](https://github.com/ChrisTitusTech/powershell-profile), [bash-profile](https://github.com/ChrisTitusTech/mybash) and [winutil](https://github.com/ChrisTitusTech/winutil)
- Mike Battista for [Powershell - WSL Interop](https://github.com/mikebattista/PowerShell-WSL-Interop)
- AndrewMast for [disable_vanguard.vbs](https://gist.github.com/AndrewMast/742ac7e07c37096017e907b0fd8ec7bb?permalink_comment_id=4616472#gistcomment-4616472)
