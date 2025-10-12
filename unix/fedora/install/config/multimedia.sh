#!/bin/bash
# Multimedia codecs and hardware acceleration

echo "Configuring multimedia support"

install_codecs=$(get_config '.multimedia.install_codecs')
enable_hw_accel=$(get_config '.multimedia.enable_hardware_accel')
swap_ffmpeg=$(get_config '.multimedia.swap_to_full_ffmpeg')

if [[ "$install_codecs" == "true" ]]; then
    log_info "Installing multimedia codecs"

    # Install multimedia group
    sudo dnf group install -y multimedia

    # Swap to full FFmpeg if configured
    if [[ "$swap_ffmpeg" == "true" ]]; then
        log_info "Swapping to full FFmpeg"
        sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
    fi

    # Update multimedia group
    sudo dnf group upgrade -y multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

    # Install GStreamer plugins
    sudo dnf install -y gstreamer1-plugins-{bad-*,good-*,base} gstreamer1-plugin-openh264 gstreamer1-libav
    sudo dnf install -y lame* --exclude=lame-devel

    # Enable OpenH264
    sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
    sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264

    log_success "Multimedia codecs installed"
fi

if [[ "$enable_hw_accel" == "true" ]]; then
    log_info "Configuring hardware acceleration"

    # Install base libraries
    sudo dnf install -y ffmpeg-libs libva libva-utils

    # Check if lspci is available
    if ! cmd_exists lspci; then
        log_info "Installing pciutils for hardware detection"
        sudo dnf install -y pciutils
    fi

    # Detect and install appropriate drivers
    if lspci | grep -i "intel.*graphics" &>/dev/null; then
        log_info "Intel graphics detected, installing Intel media drivers"
        sudo dnf swap -y libva-intel-media-driver intel-media-driver --allowerasing 2>/dev/null || \
            log_info "Intel driver swap skipped (may already be installed)"
        log_success "Intel hardware acceleration configured"
    else
        log_info "No Intel graphics detected"
    fi

    if lspci | grep -i "amd.*graphics" &>/dev/null; then
        log_info "AMD graphics detected, installing AMD drivers"
        sudo dnf install -y mesa-va-drivers mesa-vdpau-drivers
        log_success "AMD hardware acceleration configured"
    else
        log_info "No AMD graphics detected"
    fi
fi

log_success "Multimedia configuration completed"
