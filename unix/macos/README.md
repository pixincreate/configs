# macOS Setup

Automated macOS system configuration.

## Quick Start

```bash
cd ~/Dev/.configs/unix/macos
./macos-setup
```

## Configuration

Edit `config.json`:

```json
{
  "system": { "hostname": "pixmac" },
  "git": {
    "user_name": "Your Name",
    "user_email": "your@email.com"
  }
}
```

## Package Lists

Plain text files in `packages/` (one per line, `#` for comments):

- `brew.packages` - CLI tools
- `cask.packages` - GUI apps

## Adding Packages

```bash
echo "neofetch" >> packages/brew.packages
./macos-setup
```

## What It Does

- Homebrew installation and setup
- Package installation (brew, cask, Rust)
- System configuration (hostname)
- Git/SSH, NextDNS, dotfiles, ZSH

## Post-Installation

1. Add SSH key to GitHub
2. Reload shell: `exec zsh`

## Troubleshooting

### Homebrew issues

```bash
brew update
brew doctor
```

### Package fails to install

```bash
brew search package-name
brew install package-name
```

## Notes

- All scripts are idempotent (safe to re-run)
- Uses common scripts from `unix/common/`
- See [ARCHITECTURE.yml](../../ARCHITECTURE.yml) for details
