#!/bin/bash
# NVIDIA driver installation and configuration

auto_detect=$(get_config '.hardware.nvidia.auto_detect')

if [[ "$auto_detect" != "true" ]]; then
    log_info "NVIDIA auto-detection disabled, skipping"
    return 0
fi

# Detect NVIDIA GPU
if ! lspci | grep -i nvidia &>/dev/null; then
    log_info "No NVIDIA GPU detected, skipping NVIDIA setup"
    return 0
fi

echo "Configuring NVIDIA drivers"
log_info "NVIDIA GPU detected"

prefer_open=$(get_config '.hardware.nvidia.prefer_open_driver')

# Install kernel headers
log_info "Installing kernel development headers"
sudo dnf install -y kernel-devel

# Determine driver to install
if [[ "$prefer_open" == "true" ]]; then
    driver="akmod-nvidia-open"
    log_info "Using open-source NVIDIA driver (for RTX 20xx and newer)"
else
    driver="akmod-nvidia"
    log_info "Using proprietary NVIDIA driver"
fi

# Install NVIDIA drivers
log_info "Installing NVIDIA drivers"
sudo dnf install -y "$driver" xorg-x11-drv-nvidia-cuda

# Install additional NVIDIA packages
sudo dnf install -y \
    nvidia-settings \
    xorg-x11-drv-nvidia-libs.x86_64 \
    libva-nvidia-driver.x86_64 \
    vdpauinfo

# Blacklist nouveau
log_info "Blacklisting nouveau driver"
sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF

# Enable NVIDIA services
log_info "Enabling NVIDIA services"
sudo systemctl enable nvidia-hibernate.service
sudo systemctl enable nvidia-suspend.service
sudo systemctl enable nvidia-resume.service
sudo systemctl enable nvidia-powerd.service

# Build NVIDIA modules
log_info "Building NVIDIA kernel modules"
sudo akmods --force

# Regenerate initramfs
log_info "Regenerating initramfs"
sudo dracut --force

log_success "NVIDIA drivers installed"
log_warning "System reboot required for NVIDIA drivers to take effect"
