#!/bin/bash
set -eEuo pipefail

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
if sudo dnf install -y "${packages[@]}"; then
    log_success "ASUS utilities installed"
else
    log_error "Failed to install ASUS utilities"
fi

# Enable services
if sudo systemctl enable supergfxd.service 2>/dev/null; then
    log_success "supergfxd enabled"
else
    log_warning "Failed to enable supergfxd"
fi

if sudo systemctl start asusd 2>/dev/null; then
    log_success "asusd started"
else
    log_warning "Failed to start asusd"
fi

# Fix tuned-ppd platform_profile mapping for ASUS laptops
if [[ -f /sys/firmware/acpi/platform_profile_choices ]]; then
    if grep -q "quiet" /sys/firmware/acpi/platform_profile_choices 2>/dev/null; then
        log_info "Applying tuned-ppd patch for ASUS 'quiet' platform profile"

        # Find the correct Python version
        TUNED_CONTROLLER=$(find /usr/lib/python3.*/site-packages/tuned/ppd/controller.py 2>/dev/null | head -1)

        if [[ -n "$TUNED_CONTROLLER" ]] && [[ -f "$TUNED_CONTROLLER" ]]; then
            # Check if patch is already applied (idempotency)
            if grep -q '"quiet": PPD_POWER_SAVER' "$TUNED_CONTROLLER"; then
                log_info "tuned-ppd patch already applied"
            else
                # Backup original
                sudo cp "$TUNED_CONTROLLER" "${TUNED_CONTROLLER}.backup"
                log_info "Backup created: ${TUNED_CONTROLLER}.backup"

                # Apply patch: add "quiet": PPD_POWER_SAVER to PLATFORM_PROFILE_MAPPING
                if sudo sed -i '/PLATFORM_PROFILE_MAPPING = {/,/}/s/"low-power": PPD_POWER_SAVER,/"low-power": PPD_POWER_SAVER,\n    "quiet": PPD_POWER_SAVER,/' "$TUNED_CONTROLLER"; then
                    # Verify patch was applied
                    if grep -q '"quiet": PPD_POWER_SAVER' "$TUNED_CONTROLLER"; then
                        log_success "tuned-ppd patched successfully"

                        # Restart tuned-ppd
                        if sudo systemctl restart tuned-ppd 2>/dev/null; then
                            log_success "tuned-ppd restarted"
                        else
                            log_warning "Failed to restart tuned-ppd"
                        fi
                    else
                        log_error "Patch verification failed"
                        sudo cp "${TUNED_CONTROLLER}.backup" "$TUNED_CONTROLLER"
                    fi
                else
                    log_error "Failed to apply patch"
                    sudo cp "${TUNED_CONTROLLER}.backup" "$TUNED_CONTROLLER"
                fi
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

# Validate username (security: prevent command injection)
if [[ ! "$REAL_USER" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    log_error "Invalid username detected: $REAL_USER"
    return 1
fi

REAL_UID=$(id -u "$REAL_USER")
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Validate script exists and is owned by user
NOTIFY_SCRIPT="$REAL_HOME/.local/bin/asus-profile-notify.sh"
if [[ ! -f "$NOTIFY_SCRIPT" ]]; then
    log_warning "Notification script not found: $NOTIFY_SCRIPT"
    log_info "The script will be created during dotfiles installation"
fi

# Verify ownership if script exists
if [[ -f "$NOTIFY_SCRIPT" ]]; then
    SCRIPT_OWNER=$(stat -c '%U' "$NOTIFY_SCRIPT" 2>/dev/null || stat -f '%Su' "$NOTIFY_SCRIPT" 2>/dev/null)
    if [[ "$SCRIPT_OWNER" != "$REAL_USER" ]]; then
        log_error "Script not owned by user: $NOTIFY_SCRIPT"
        log_error "Owner: $SCRIPT_OWNER, Expected: $REAL_USER"
        return 1
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

# Create udev rule that triggers systemd service (secure version)
sudo tee /etc/udev/rules.d/99-asus-profile-toast.rules > /dev/null <<EOF
# Trigger notification when ASUS platform profile changes (Fn+F5)
# Security: Uses systemd service instead of direct sudo execution
KERNEL=="platform-profile-*", \\
    SUBSYSTEM=="platform-profile", \\
    ACTION=="change", \\
    TAG+="systemd", \\
    ENV{SYSTEMD_USER}="$REAL_USER", \\
    ENV{SYSTEMD_WANTS}="asus-profile-notify@$REAL_USER.service"
EOF

sudo chmod 644 /etc/udev/rules.d/99-asus-profile-toast.rules

# Reload udev rules and systemd
sudo udevadm control --reload-rules
sudo systemctl daemon-reload

log_success "ASUS system optimizations applied"
