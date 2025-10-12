# omaforge - macOS

Automated macOS system setup.

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
  },
  "rust": {
    "tools": ["bat", "eza", "ripgrep", "zoxide", "starship"]
  }
}
```

## Package Management

### Interactive

```bash
./bin/omaforge-pkg-manage
```

Add, remove, search packages with availability checking.

### Manual

```bash
echo "fastfetch" >> packages/brew.packages
./macos-setup
```

### Package Lists

- `brew.packages` - CLI tools
- `cask.packages` - GUI applications

## What's Installed

- Homebrew setup
- Packages (Homebrew, Cask, Rust)
- System configuration (hostname)
- Git/SSH, NextDNS, dotfiles, ZSH

## Reset/Re-run Components

If you need to reset or re-run specific parts:

```bash
./bin/omaforge-reset
```

Interactive menu to reset:

- ZSH configuration
- Dotfiles (stow)
- Fonts
- Git & SSH
- NextDNS
- Rust tools

## Post-Install

1. Add SSH key to GitHub:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
2. Reload shell:
   ```bash
   exec zsh
   ```

## Troubleshooting

### Homebrew issues

```bash
brew update
brew doctor
```

### Package install fails

```bash
brew search package-name
brew install package-name
```

## Notes

- All scripts are idempotent (safe to re-run)
- Uses shared scripts from `unix/common/`
- See [main README](../../README.md) for overview
