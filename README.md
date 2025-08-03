# Configs

This repo contains all of my development configs. I never had a backup of these before and hence this repo.

## Contents

Check repo [tree](./docs/TREE.md) to get list of file contents.

## One line installer

### If the machine runs Windows, execute below command in [powershell](https://github.com/PowerShell/PowerShell)

> [!NOTE]
> If this is a fresh Windows installation, it is recommended to re-do the Windows installation with `MicroWin`:
>
> 1. Download the latest Windows 11 (recommended) ISO (international edition)
> 2. Open winutil (in elevated powershell, execute the following command: `irm "christitus.com/win" | iex`) and go to `MicroWin` tab
> 3. Follow the instructions (do not select any drivers or inject them)
> 4. Wait until ISO is created. Use `Rufus` to make a bootable drive
> 5. Re-do the installation by booting from USB (Change boot priority in `UEFI` menu)

```pwsh
irm "https://github.com/pixincreate/configs/raw/main/windows/powershell/setup.ps1" | iex
```

### If the machine is using unix based OS, execute below in terminal

> [!NOTE]
> Unix based OS here means, `WSL`, `Debian`, `Fedora`, or `macOS`. The setup script will automatically detect your distribution and run the appropriate setup.

If the machine runs Windows that have networking tool like [Portmaster](https://safing.io) installed, `WSL` will have hard time establishing networking connection. Hence, it is recommended to execute the below command in `WSL` terminal before calling `setup` script. This will bypass the DNS restrictions imposed by `Portmaster`:

```sh
echo 'nameserver 9.9.9.9' | sudo tee -a /etc/resolv.conf
```

> [!WARNING]
> If tools like `Docker` have hard time connecting to the internet even after changing the DNS, it is recommended to shut down the `Portmaster` tool.

**For Debian/Ubuntu/WSL:**

```sh
sudo apt-get update && sudo apt-get install -y curl git wget zsh && \
    bash -c "$(curl -sSL https://github.com/pixincreate/configs/raw/main/unix/setup.sh)" -- --setup
```

**For Fedora KDE:**

> [!NOTE]
> Comprehensive Fedora KDE setup with NVIDIA support, gaming, development environment, and Kanagawa Dragon theming.

For a complete Fedora installation following the detailed setup guide in [`docs/FEDORA_SETUP_GUIDE.md`](docs/FEDORA_SETUP_GUIDE.md).

```sh
sudo dnf install -y curl git wget zsh && \
    bash -c "$(curl -sSL https://github.com/pixincreate/configs/raw/main/unix/setup.sh)" -- --setup
```

Features included:

- 🎮 **NVIDIA GTX 1650Ti support** with stable drivers
- 🛠 **Complete development environment** (Rust, Node.js, Python, Java, C/C++)
- 🎨 **Kanagawa Dragon theme** system-wide
- 📦 **Single source of truth** for package management
- 🔒 **Stability-first approach** - nothing breaks with updates
- 🎯 **Gaming setup** with Steam, Lutris, and optimizations
- 🎬 **DaVinci Resolve** ready for video editing

See `fedora/README.md` for detailed usage and `docs/SETUP_GUIDE.md` for complete installation instructions.

**For macOS:**

```sh
bash -c "$(curl -sSL https://github.com/pixincreate/configs/raw/main/unix/setup.sh)" -- --setup
```

If running in Termux

```sh
pkg update && pkg upgrade -y && pkg install -y curl git wget zsh && \
    bash -c "$(curl -sSL https://github.com/pixincreate/configs/raw/main/unix/setup.sh)" -- --setup

```

#### Vanguard Controller

To learn about what Vanguard controller is and how to use it, refer to [Vanguard Controller](./docs/VANGUARD.md)

## Credits

- SanchithHegde for [dotfiles](https://github.com/SanchithHegde/dotfiles)
- Chris Titus for [powershell-profile](https://github.com/ChrisTitusTech/powershell-profile), [bash-profile](https://github.com/ChrisTitusTech/mybash) and [winutil](https://github.com/ChrisTitusTech/winutil)
- Mike Battista for [Powershell - WSL Interop](https://github.com/mikebattista/PowerShell-WSL-Interop)
- AndrewMast for [disable_vanguard.vbs](https://gist.github.com/AndrewMast/742ac7e07c37096017e907b0fd8ec7bb?permalink_comment_id=4616472#gistcomment-4616472)
