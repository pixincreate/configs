# Fedora Setup

Automated Fedora system setup.

## Quick Start

## Quick Start

````bash
cd ~/Dev/.configs/unix/fedora
./fedora-setup

### Adding Packages

EditMain```bash
# configurationAdd DNF package
echo "neofetch" >> packages/basepackages

# Add Flatpak app
echo "org.mozilla.firefox" >> packages/flatpak.packages

# Run setup (idempotent - won't reinstall existing)
./fedora-setup
fedoralaptop    "user_email": "your@email.com"
  },

## Package Lists

Plain text files in `packages/` (one per line, `#` for comments):

- `base.packages` - Core utilities
- `development.packages` - Dev tools
- `tools.packages` - User apps
- `flatpak.packages` - Flatpak apps

## Adding Packages

```bash
echo "neofetch" >> packages/base.packages
./fedora-setup
````

## What It Does

- DNF optimization and system updates
- Repository setup (RPM Fusion, COPR, external)
- Package installation (DNF, Flatpak, Rust)
- Hardware support (ASUS, NVIDIA)
- Performance tuning (zram, fstrim)
- Git/SSH, NextDNS, dotfiles, ZSH
- System services (PostgreSQL, Redis, Docker)

## Post-Installation

1. **Logout/login** - Group changes take effect (docker, etc.)
2. **Reboot** - If NVIDIA drivers were installed
3. **Add SSH key to GitHub:**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   # Add to https://github.com/settings/keys
   ```
4. **Enroll MOK for Secure Boot** (if prompted):
   ```bash
   mokutil --import /path/to/MOK.der
   # Reboot and follow on-screen enrollment
   ```
   /changesReload shell:execzsh

## Troubleshooting

### failinstall

```bash
# Check logs        # Check repositories
journalctl -xe

# Verify configuration
cat config.json | jq       # Refresh cache
```

### Git Config Not Applied

### Git config issues

PackagesInstall#Verifyrepositories
dnf repolist

# Refresh cache

dnf makecache

# Try installing manually

dnf install package```bash

# Verify local config

cat ~/.config/gitconfig/.gitconfig.local

# Check Git config

git config --list

# Check SSH keys

ls -la ~/.ssh/

````

### Services Don't Start

Expected in containers. On real hardware:

```bash
# Check service status
systemctl status service-name

# View logs
journalctl -u service-name -n 50

# Check if enabled
systemctl is-enabled service-name
````

### Stow Conflicts

```bash
# Manually adopt conflicting files
cd ~/Dev/.configs/home
stow --adopt config

# Or delete conflicting files first
rm ~/.config/conflicting-file
stow config
```

## Advanced Usage

### Environment Variables

```bash
# Non-interactive mode
NON_INTERACTIVE=true ./fedora-setup

# Custom config file
FEDORA_CONFIG=/path/to/custom-config.json ./fedora-setup

# Custom paths
FEDORA_PATH=/custom/path ./fedora-setup
```

### Dry Run Testing

No built-in dry run, but you can:

1. Test in container (OrbStack/Podman)
2. Review package lists before running
3. Run phases one-by-one
4. Check config.json syntax: `cat config.json | jq`

### Custom Scripts

Add your own scripts to `install/` directories:

```bash
# Create custom script
cat > install/config/custom.sh <<'EOF'
#!/bin/bash
echo "Running custom configuration"
# Your code here
EOF

# Source it in install/config/all.sh
echo 'source "$FEDORA_INSTALL/config/custom.sh"' >> install/config/all.sh
```

### Services Don't Start

Expected in containers. On real hardware:

```bash
systemctl status service-name
journalctl -xe
```

## Notes

- All scripts are idempotent (safe to re-run)
- Color-coded logging for clarity
- Hardware auto-detection where possible
- Uses common scripts from `unix/common/` for cross-platform compatibility
- All scripts are idempotent (safe to re-run)
- Uses common scripts from `unix/common/`
- See [ARCHITECTURE.yml](../../ARCHITECTURE.yml) for details
- All scripts are idempotent (safe to re-run)
- Uses common scripts from `unix/common/` for cross-platform compatibility
- Color-coded logging for clarity
- Hardware auto-detection where possible
- Container-friendly (skips hardware/firmware when in container)
