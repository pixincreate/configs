#!/bin/bash
set -eEuo pipefail

# Migration: Fix ASUS power profile switching
#
# This migration:
# - Removes obsolete polkit rule (profile switching now handled by tuned-ppd)
# - Updates udev rule with proper comment
# - Applies tuned-ppd patch for ASUS "quiet" platform profile support
# - Fixes SELinux contexts

echo "Running migration: Fix ASUS power profile switching"

# Only run on ASUS systems
if ! sudo dmidecode -s system-manufacturer 2>/dev/null | grep -qi asus; then
    echo "[INFO] Not an ASUS system, skipping migration"
    exit 0
fi

echo "[INFO] ASUS system detected, applying migration..."

# 1. Remove obsolete polkit rule
if [[ -f /etc/polkit-1/rules.d/49-asus-profile.rules ]]; then
    echo "[INFO] Removing obsolete polkit rule..."
    sudo rm -f /etc/polkit-1/rules.d/49-asus-profile.rules
    sudo systemctl restart polkit 2>/dev/null || true
    echo "[SUCCESS] Polkit rule removed"
fi

# 2. Update udev rule - SECURITY HARDENED VERSION
echo "[INFO] Updating udev rule..."

REAL_USER="${SUDO_USER:-$USER}"

# Validate username (prevent command injection)
if [[ ! "$REAL_USER" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "[ERROR] Invalid username detected: $REAL_USER"
    exit 1
fi

REAL_UID=$(id -u "$REAL_USER")
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Validate script exists and is owned by user
NOTIFY_SCRIPT="$REAL_HOME/.local/bin/asus-profile-notify.sh"
if [[ ! -f "$NOTIFY_SCRIPT" ]]; then
    echo "[WARNING] Notification script not found: $NOTIFY_SCRIPT"
    echo "[INFO] The script will be created during dotfiles installation"
    echo "[INFO] udev rule will be configured but won't work until script exists"
fi

# Verify ownership and permissions if script exists
if [[ -f "$NOTIFY_SCRIPT" ]]; then
    SCRIPT_OWNER=$(stat -c '%U' "$NOTIFY_SCRIPT" 2>/dev/null || stat -f '%Su' "$NOTIFY_SCRIPT" 2>/dev/null)
    if [[ "$SCRIPT_OWNER" != "$REAL_USER" ]]; then
        echo "[ERROR] Script not owned by user: $NOTIFY_SCRIPT"
        echo "[ERROR] Owner: $SCRIPT_OWNER, Expected: $REAL_USER"
        exit 1
    fi
fi

# Create systemd user service (safer than sudo in udev)
sudo tee /etc/systemd/system/asus-profile-notify@.service > /dev/null <<'EOF'
[Unit]
Description=ASUS Profile Change Notification for %i

[Service]
Type=oneshot
User=%i
Environment="DISPLAY=:0"
ExecStart=%h/.local/bin/asus-profile-notify.sh
EOF

# Create udev rule that triggers systemd service
sudo tee /etc/udev/rules.d/99-asus-profile-toast.rules > /dev/null <<EOF
# Trigger notification when ASUS platform profile changes (Fn+F5)
KERNEL=="platform-profile-*", \\
    SUBSYSTEM=="platform-profile", \\
    ACTION=="change", \\
    TAG+="systemd", \\
    ENV{SYSTEMD_USER}="$REAL_USER", \\
    ENV{SYSTEMD_WANTS}="asus-profile-notify@$REAL_USER.service"
EOF

sudo chmod 644 /etc/udev/rules.d/99-asus-profile-toast.rules
sudo udevadm control --reload-rules
sudo systemctl daemon-reload
echo "[SUCCESS] Udev rule and systemd service updated (hardened)"

# 3. Apply tuned-ppd patch if system has "quiet" profile
if [[ -f /sys/firmware/acpi/platform_profile_choices ]]; then
    if grep -q "quiet" /sys/firmware/acpi/platform_profile_choices 2>/dev/null; then
        echo "[INFO] System has 'quiet' platform profile, applying tuned-ppd patch..."

        # Find the correct Python version
        TUNED_CONTROLLER=$(find /usr/lib/python3.*/site-packages/tuned/ppd/controller.py 2>/dev/null | head -1)

        if [[ -n "$TUNED_CONTROLLER" ]] && [[ -f "$TUNED_CONTROLLER" ]]; then
            # Check if patch is already applied (idempotency)
            if grep -q '"quiet": PPD_POWER_SAVER' "$TUNED_CONTROLLER"; then
                echo "[INFO] Patch already applied, skipping"
            else
                # Backup original
                sudo cp "$TUNED_CONTROLLER" "${TUNED_CONTROLLER}.backup"
                echo "[INFO] Created backup: ${TUNED_CONTROLLER}.backup"

                # Apply patch
                sudo sed -i '/PLATFORM_PROFILE_MAPPING = {/,/}/s/"low-power": PPD_POWER_SAVER,/"low-power": PPD_POWER_SAVER,\n    "quiet": PPD_POWER_SAVER,/' "$TUNED_CONTROLLER"

                # Verify patch was applied
                if grep -q '"quiet": PPD_POWER_SAVER' "$TUNED_CONTROLLER"; then
                    echo "[SUCCESS] Patch applied successfully"

                    # Restart tuned-ppd
                    if sudo systemctl restart tuned-ppd; then
                        echo "[SUCCESS] tuned-ppd restarted"
                    else
                        echo "[WARNING] Failed to restart tuned-ppd, may require manual restart"
                    fi
                else
                    echo "[ERROR] Failed to apply patch"
                    # Restore from backup
                    sudo cp "${TUNED_CONTROLLER}.backup" "$TUNED_CONTROLLER"
                    echo "[INFO] Restored from backup"
                    exit 1
                fi
            fi
        else
            echo "[WARNING] tuned-ppd controller.py not found"
            echo "[INFO] Skipping patch (tuned-ppd may not be installed)"
        fi

        # Fix SELinux context
        if [[ -f /etc/tuned/ppd_base_profile ]]; then
            echo "[INFO] Fixing SELinux context..."
            sudo restorecon -v /etc/tuned/ppd_base_profile 2>/dev/null || true
            echo "[SUCCESS] SELinux context fixed"
        fi
    else
        echo "[INFO] System does not have 'quiet' platform profile, skipping tuned-ppd patch"
    fi
else
    echo "[INFO] /sys/firmware/acpi/platform_profile_choices not found, skipping tuned-ppd patch"
fi

echo ""
echo "[SUCCESS] Migration completed successfully!"
echo ""
echo "Summary:"
echo "  - Removed obsolete polkit rule for manual profile switching"
echo "  - Updated udev rule for toast notifications"
echo "  - Applied tuned-ppd patch (if applicable)"
echo ""
echo "Power profile switching via Fn+F5 should now work correctly."
echo "Press Fn+F5 to test - you should see toast notifications and"
echo "all three profiles (Quiet/Balanced/Performance) should cycle properly."
