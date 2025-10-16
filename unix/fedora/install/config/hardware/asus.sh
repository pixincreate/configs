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

# Configure udev rules for profile notifications
log_info "Setting up ASUS profile change notifications"

# Get the actual user (not root)
REAL_USER="${SUDO_USER:-$USER}"
REAL_UID=$(id -u "$REAL_USER")
REAL_HOME=$(eval echo "~$REAL_USER")

sudo tee /etc/udev/rules.d/99-asus-profile-toast.rules > /dev/null <<EOF
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

# Configure polkit for profile switching
sudo tee /etc/polkit-1/rules.d/49-asus-profile.rules > /dev/null <<'EOF'
// Allow switching TuneD profiles from udev/inactive sessions
polkit.addRule(function(action, subject) {
    if (action.id == "com.redhat.tuned.switch_profile") {
        return polkit.Result.YES;
    }
});
EOF

sudo chmod 644 /etc/polkit-1/rules.d/49-asus-profile.rules
sudo chmod 644 /etc/udev/rules.d/99-asus-profile-toast.rules

# Restart services
sudo systemctl restart polkit
sudo udevadm control --reload-rules

log_success "ASUS system optimizations applied"
