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
  },
  "rust": {
    "tools": ["bat", "eza", "ripgrep", "zoxide", "starship"]
  }
}
```

## Package Lists

Plain text files in `packages/` (one per line, `#` for comments):

- `brew.packages` - CLI tools
- `cask.packages` - GUI apps

## Adding Packages

```bash
# Add CLI tool
echo "neofetch" >> packages/brew.packages

# Add GUI app
echo "firefox" >> packages/cask.packages

# Run setup (idempotent - safe to re-run)
./macos-setup
```

## What It Does

- Homebrew installation and setup
- Package installation (brew, cask, Rust)
- System configuration (hostname)
- Git/SSH, NextDNS, dotfiles, ZSH

## Post-Installation

1. **Add SSH key to GitHub:**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
2. **Reload shell:**
   ```bash
   exec zsh
   ```

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
