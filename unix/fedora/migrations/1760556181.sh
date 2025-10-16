#!/bin/bash
# Migration: Replace udev-based ASUS profile sync with D-Bus approach
# Removes old udev rule and asus-profile-notify.sh
# Enables new systemd user service for D-Bus monitoring

echo "Running migration: ASUS Profile Sync - udev to D-Bus migration"

# Check if this is an ASUS system
if ! sudo dmidecode -s system-manufacturer 2>/dev/null | grep -qi asus; then
    echo "Not an ASUS system, skipping migration"
    exit 0
fi

echo "Stopping old udev-based profile sync..."

if [[ -f /etc/udev/rules.d/99-asus-profile-toast.rules ]]; then
    echo "Removing old udev rule: /etc/udev/rules.d/99-asus-profile-toast.rules"
    sudo rm -f /etc/udev/rules.d/99-asus-profile-toast.rules
    sudo udevadm control --reload-rules
    echo "Old udev rule removed"
else
    echo "Old udev rule not found (already removed or never existed)"
fi

OLD_SCRIPT="$HOME/.local/bin/asus-profile-notify.sh"
if [[ -f "$OLD_SCRIPT" ]]; then
    echo "Removing old script: $OLD_SCRIPT"
    rm -f "$OLD_SCRIPT"
    echo "Old script removed"
else
    echo "Old script not found (already removed or never existed)"
fi

echo "Cleaning up old lock and state files..."
rm -f "${XDG_RUNTIME_DIR:-/tmp}/asus-profile-notify.lock"
rm -f "${XDG_RUNTIME_DIR:-/tmp}/asus-profile-last-state"
rm -f "${XDG_RUNTIME_DIR:-/tmp}/asus-profile-debounce"
rm -f "${XDG_RUNTIME_DIR:-/tmp}/asus-profile-timestamp"
rm -f /tmp/asus-profile-notify.lock
rm -f /tmp/asus-profile-last-state
echo "Cleaned up temporary files"

NEW_SCRIPT="$HOME/.local/bin/asus-profile-sync.sh"
NEW_SERVICE="$HOME/.config/systemd/user/asus-profile-sync.service"

if [[ ! -f "$NEW_SCRIPT" ]] || [[ ! -f "$NEW_SERVICE" ]]; then
    echo "New files not found, attempting to stow 'home' package..."

    CONFIGS_DIR="$HOME/Dev/.configs"
    if [[ ! -d "$CONFIGS_DIR" ]]; then
        echo "ERROR: Configs directory not found at $CONFIGS_DIR"
        echo "Please ensure your dotfiles are cloned to $CONFIGS_DIR"
        exit 1
    fi

    COMMON_HELPERS="$CONFIGS_DIR/unix/fedora/install/helpers/common.sh"
    if [[ -f "$COMMON_HELPERS" ]]; then
        source "$COMMON_HELPERS"
    fi

    STOW_SCRIPT="$CONFIGS_DIR/unix/common/dotfiles/stow.sh"
    if [[ ! -f "$STOW_SCRIPT" ]]; then
        echo "ERROR: Stow script not found at $STOW_SCRIPT"
        exit 1
    fi

    source "$STOW_SCRIPT"

    if stow_dotfiles "$CONFIGS_DIR/home" "$HOME" local; then
        echo "Stowed home/local package"
    else
        echo "ERROR: Failed to stow home/local package"
        exit 1
    fi

    if [[ ! -f "$NEW_SCRIPT" ]]; then
        echo "ERROR: $NEW_SCRIPT still not found after stowing"
        exit 1
    fi

    if [[ ! -f "$NEW_SERVICE" ]]; then
        echo "ERROR: $NEW_SERVICE still not found after stowing"
        exit 1
    fi

    echo "New files successfully deployed"
else
    echo "New files already exist"
fi

echo "Reloading systemd user daemon..."
systemctl --user daemon-reload

echo "Enabling and starting new D-Bus monitoring service..."
systemctl --user enable asus-profile-sync.service
systemctl --user restart asus-profile-sync.service

if systemctl --user is-active --quiet asus-profile-sync.service; then
    echo "asus-profile-sync.service is running"
else
    echo "⚠ WARNING: asus-profile-sync.service failed to start"
    echo "Check status with: systemctl --user status asus-profile-sync.service"
    exit 1
fi

echo ""
echo "Migration completed successfully!"
echo ""
echo "Summary of changes:"
echo "  - Removed: /etc/udev/rules.d/99-asus-profile-toast.rules"
echo "  - Removed: ~/.local/bin/asus-profile-notify.sh"
echo "  - Added: ~/.local/bin/asus-profile-sync.sh"
echo "  - Added: ~/.config/systemd/user/asus-profile-sync.service"
echo "  - Enabled: asus-profile-sync.service (D-Bus monitoring)"
echo ""
echo "You can now test by pressing Fn+F5 to change power profiles"
echo "Monitor logs with: journalctl --user -u asus-profile-sync.service -f"
