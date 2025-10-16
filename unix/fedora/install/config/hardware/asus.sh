#!/bin/bash
# ASUS system optimizations

auto_detect=$(get_config '.hardware.asus.auto_detect')

if [[ "$auto_detect" != "true" ]]; then
    log_info "ASUS auto-detection disabled, skipping"
    return 0
fi

# Detect ASUS system
if ! sudo dmidecode -s system-manufacturer 2>/dev/null | grep -qi asus; then
    log_info "Not an ASUS system, skipping ASUS optimizations"
    return 0
fi

echo "Configuring ASUS system optimizations"
log_info "ASUS system detected"

# Get packages from config
mapfile -t packages < <(get_config_array '.hardware.asus.packages')

if [[ ${#packages[@]} -eq 0 ]]; then
    log_warning "No ASUS packages configured"
    return 0
fi

# Install ASUS packages
log_info "Installing ASUS utilities"
sudo dnf install -y "${packages[@]}"

# Enable services
sudo systemctl enable supergfxd.service || log_warning "Failed to enable supergfxd"
sudo systemctl start asusd || log_warning "Failed to start asusd"

# Fix tuned-ppd platform_profile mapping for ASUS laptops
if [[ -f /sys/firmware/acpi/platform_profile_choices ]]; then
    if grep -q "quiet" /sys/firmware/acpi/platform_profile_choices 2>/dev/null; then
        log_info "Applying tuned-ppd patch for ASUS 'quiet' platform profile"

        # Find the correct Python version
        TUNED_CONTROLLER=$(find /usr/lib/python3.*/site-packages/tuned/ppd/controller.py 2>/dev/null | head -1)

        if [[ -n "$TUNED_CONTROLLER" ]] && [[ -f "$TUNED_CONTROLLER" ]]; then
            # Check if patch is already applied
            if ! grep -q '"quiet": PPD_POWER_SAVER' "$TUNED_CONTROLLER"; then
                # Backup original
                sudo cp "$TUNED_CONTROLLER" "${TUNED_CONTROLLER}.backup"

                # Apply patch: add "quiet": PPD_POWER_SAVER to PLATFORM_PROFILE_MAPPING
                sudo sed -i '/PLATFORM_PROFILE_MAPPING = {/,/}/s/"low-power": PPD_POWER_SAVER,/"low-power": PPD_POWER_SAVER,\n    "quiet": PPD_POWER_SAVER,/' "$TUNED_CONTROLLER"

                log_info "tuned-ppd patched successfully"

                # Restart tuned-ppd
                sudo systemctl restart tuned-ppd
                log_info "tuned-ppd restarted"
            else
                log_info "tuned-ppd patch already applied"
            fi
        else
            log_warning "tuned-ppd controller.py not found, skipping patch"
        fi

        # Fix SELinux context
        if [[ -f /etc/tuned/ppd_base_profile ]]; then
            sudo restorecon -v /etc/tuned/ppd_base_profile 2>/dev/null || true
        fi
    fi
fi

log_info "Setting up ASUS profile change notifications"

# Get the actual user (not root)
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

# Reload udev rules
sudo udevadm control --reload-rules

log_success "ASUS system optimizations applied"
