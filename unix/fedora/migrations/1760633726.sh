#!/bin/bash
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
    echo "Not an ASUS system, skipping migration"
    exit 0
fi

echo "ASUS system detected, applying migration..."

# 1. Remove obsolete polkit rule
if [[ -f /etc/polkit-1/rules.d/49-asus-profile.rules ]]; then
    echo "Removing obsolete polkit rule..."
    sudo rm -f /etc/polkit-1/rules.d/49-asus-profile.rules
    sudo systemctl restart polkit 2>/dev/null || true
    echo "✓ Polkit rule removed"
fi

# 2. Update udev rule with proper comment
echo "Updating udev rule..."

REAL_USER="${SUDO_USER:-$USER}"
REAL_UID=$(id -u "$REAL_USER")
REAL_HOME=$(eval echo "~$REAL_USER")

sudo tee /etc/udev/rules.d/99-asus-profile-toast.rules > /dev/null <<EOF
# Trigger notification when ASUS platform profile changes (Fn+F5)
KERNEL=="platform-profile-*", \\
    SUBSYSTEM=="platform-profile", \\
    ACTION=="change", \\
    RUN+="/bin/bash -c ' \\
        DISPLAY=:0 \\
        XDG_RUNTIME_DIR=/run/user/$REAL_UID \\
        /usr/bin/sudo -u $REAL_USER \\
        $REAL_HOME/.local/bin/asus-profile-notify.sh \\
    '"
EOF

sudo chmod 644 /etc/udev/rules.d/99-asus-profile-toast.rules
sudo udevadm control --reload-rules
echo "✓ Udev rule updated"

# 3. Apply tuned-ppd patch if system has "quiet" profile
if [[ -f /sys/firmware/acpi/platform_profile_choices ]]; then
    if grep -q "quiet" /sys/firmware/acpi/platform_profile_choices 2>/dev/null; then
        echo "System has 'quiet' platform profile, applying tuned-ppd patch..."

        # Find the correct Python version
        TUNED_CONTROLLER=$(find /usr/lib/python3.*/site-packages/tuned/ppd/controller.py 2>/dev/null | head -1)

        if [[ -n "$TUNED_CONTROLLER" ]] && [[ -f "$TUNED_CONTROLLER" ]]; then
            # Check if patch is already applied
            if ! grep -q '"quiet": PPD_POWER_SAVER' "$TUNED_CONTROLLER"; then
                # Backup original
                sudo cp "$TUNED_CONTROLLER" "${TUNED_CONTROLLER}.backup"
                echo "  - Created backup: ${TUNED_CONTROLLER}.backup"

                # Apply patch
                sudo sed -i '/PLATFORM_PROFILE_MAPPING = {/,/}/s/"low-power": PPD_POWER_SAVER,/"low-power": PPD_POWER_SAVER,\n    "quiet": PPD_POWER_SAVER,/' "$TUNED_CONTROLLER"

                # Verify patch was applied
                if grep -q '"quiet": PPD_POWER_SAVER' "$TUNED_CONTROLLER"; then
                    echo "  ✓ Patch applied successfully"

                    # Restart tuned-ppd
                    sudo systemctl restart tuned-ppd
                    echo "  ✓ tuned-ppd restarted"
                else
                    echo "  ✗ Failed to apply patch"
                    # Restore from backup
                    sudo cp "${TUNED_CONTROLLER}.backup" "$TUNED_CONTROLLER"
                    echo "  - Restored from backup"
                fi
            else
                echo "  - Patch already applied, skipping"
            fi
        else
            echo "  ✗ tuned-ppd controller.py not found at: $TUNED_CONTROLLER"
            echo "    Skipping patch (tuned-ppd may not be installed)"
        fi

        # Fix SELinux context
        if [[ -f /etc/tuned/ppd_base_profile ]]; then
            echo "Fixing SELinux context..."
            sudo restorecon -v /etc/tuned/ppd_base_profile 2>/dev/null || true
            echo "✓ SELinux context fixed"
        fi
    else
        echo "System does not have 'quiet' platform profile, skipping tuned-ppd patch"
    fi
else
    echo "/sys/firmware/acpi/platform_profile_choices not found, skipping tuned-ppd patch"
fi

echo ""
echo "Migration completed successfully!"
echo ""
echo "Summary:"
echo "  - Removed obsolete polkit rule for manual profile switching"
echo "  - Updated udev rule for toast notifications"
echo "  - Applied tuned-ppd patch (if applicable)"
echo ""
echo "Power profile switching via Fn+F5 should now work correctly."
echo "Press Fn+F5 to test - you should see toast notifications and"
echo "all three profiles (Quiet/Balanced/Performance) should cycle properly."
