#!/bin/bash
# Add configurable shutdown timeout and swappiness settings
# Restow browser flags and osaka jade wallpapers
# Configure Firefox smooth scrolling

echo "Running migration: Add shutdown timeout, swappiness, and restow configs"

CONFIG_FILE="$HOME/Dev/.configs/unix/fedora/config.json"

SHUT_OFF_TIME=$(jq -r '.performance.shut_off_time // empty' "$CONFIG_FILE" 2>/dev/null)

if [ -n "$SHUT_OFF_TIME" ] && [ "$SHUT_OFF_TIME" != "null" ]; then
    echo "Applying systemd shutdown timeout: ${SHUT_OFF_TIME}s"

    sudo mkdir -p /etc/systemd/system.conf.d

    sudo tee /etc/systemd/system.conf.d/10-faster-shutdown.conf > /dev/null <<EOF
[Manager]
DefaultTimeoutStopSec=${SHUT_OFF_TIME}s
EOF

    sudo systemctl daemon-reload
    echo "Shutdown timeout configured"
fi

SWAPPINESS=$(jq -r '.performance.swappiness // empty' "$CONFIG_FILE" 2>/dev/null)

if [ -n "$SWAPPINESS" ] && [ "$SWAPPINESS" != "null" ]; then
    echo "Applying performance settings: swappiness=${SWAPPINESS}"

    # Create file if it doesn't exist
    sudo touch /etc/sysctl.d/99-performance.conf

    # Add tcp_mtu_probing if not present (network performance)
    if ! grep -q "net.ipv4.tcp_mtu_probing" /etc/sysctl.d/99-performance.conf; then
        echo "net.ipv4.tcp_mtu_probing=1" | sudo tee -a /etc/sysctl.d/99-performance.conf > /dev/null
    fi

    # Add swappiness if not present
    if ! grep -q "vm.swappiness" /etc/sysctl.d/99-performance.conf; then
        echo "vm.swappiness=${SWAPPINESS}" | sudo tee -a /etc/sysctl.d/99-performance.conf > /dev/null
    fi

    sudo sysctl --system > /dev/null
    echo "Performance settings configured"
fi

# Restow browser flags (Brave & Chromium)
echo "Restowing browser Wayland flags"

STOW_SOURCE=$(jq -r '.dotfiles.stow_source // empty' "$CONFIG_FILE" 2>/dev/null)
STOW_SOURCE=${STOW_SOURCE/#\~/$HOME}

if [ -d "$STOW_SOURCE/config/.config" ]; then
    # Restow config package to update browser flags
    cd "$STOW_SOURCE" && stow -R config 2>/dev/null
    echo "Browser flags restowed (brave-flags.conf, chromium-flags.conf)"
else
    echo "Stow source not found: $STOW_SOURCE"
fi

# Restow osaka jade wallpapers
echo "Restowing osaka jade wallpapers"

if [ -d "$STOW_SOURCE/Pictures" ]; then
    # Restow Pictures package to update wallpapers
    cd "$STOW_SOURCE" && stow -R Pictures 2>/dev/null
    echo "Osaka jade wallpapers restowed (1-osaka-jade-bg.jpg, 2-osaka-jade-bg.jpg, 3-osaka-jade-bg.jpg)"
else
    echo "Pictures source not found: $STOW_SOURCE/Pictures"
fi



echo "Migration completed successfully"
