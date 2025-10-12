#!/bin/bash

auto_detect=$(get_config '.hardware.nvidia.auto_detect')

if [[ "$auto_detect" != "true" ]]; then
    log_info "NVIDIA auto-detection disabled, skipping"
    return 0
fi

if ! lspci | grep -i nvidia &>/dev/null; then
    log_info "No NVIDIA GPU detected, skipping NVIDIA setup"
    return 0
fi

echo "Configuring NVIDIA drivers"
log_info "NVIDIA GPU detected"

log_info "Installing kernel development headers"
sudo dnf install -y kernel-devel

log_info "Installing NVIDIA drivers"
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

log_info "Installing NVIDIA utilities"
sudo dnf install -y nvidia-settings

log_info "Installing NVIDIA Power"
sudo dnf install -y xorg-x11-drv-nvidia-power

log_info "Installing NVIDIA libraries (x86_64 only)"
sudo dnf install -y xorg-x11-drv-nvidia-libs.x86_64

log_info "Installing VAAPI and VDPAU support"
sudo dnf remove -y libva-nvidia-driver 2>/dev/null || true
sudo dnf install -y libva-nvidia-driver.x86_64 vdpauinfo

log_info "Blacklisting nouveau driver"
sudo tee /etc/modprobe.d/blacklist.conf >/dev/null <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF

log_info "Building NVIDIA kernel modules"
sudo akmods --force

log_info "Enabling NVIDIA services"
sudo systemctl enable nvidia-{suspend,resume,hibernate}

log_info "Regenerating initramfs"
sudo dracut --force

log_success "NVIDIA drivers installed"
log_warning "System reboot required for NVIDIA drivers to take effect"
