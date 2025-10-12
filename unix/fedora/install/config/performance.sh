#!/bin/bash
# System performance optimizations

echo "Applying performance optimizations"

# Configure zram
enable_zram=$(get_config '.performance.enable_zram')
zram_size=$(get_config '.performance.zram_size_mb')

if [[ "$enable_zram" == "true" ]]; then
    log_info "Configuring zram swap"

    sudo tee /etc/systemd/zram-generator.conf > /dev/null <<EOF
[zram0]
zram-size = ${zram_size:-24576}
compression-algorithm = zstd
EOF

    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl enable systemd-zram-setup@zram0.service 2>/dev/null || true

    if sudo systemctl restart systemd-zram-setup@zram0.service 2>/dev/null; then
        log_success "zram configured with ${zram_size:-24576}MB"
    else
        log_info "zram setup skipped"
    fi
fi

# Enable systemd-oomd
enable_oomd=$(get_config '.performance.enable_oomd')

if [[ "$enable_oomd" == "true" ]]; then
    log_info "Enabling systemd-oomd (Out-of-Memory Daemon)"

    if sudo systemctl enable --now systemd-oomd 2>/dev/null; then
        log_success "systemd-oomd enabled"
    else
        log_info "systemd-oomd not available in this environment"
    fi
fi

# Enable fstrim for SSDs
enable_fstrim=$(get_config '.performance.enable_fstrim')

if [[ "$enable_fstrim" == "true" ]]; then
    log_info "Enabling fstrim timer for SSD optimization"

    if sudo systemctl enable --now fstrim.timer 2>/dev/null; then
        log_success "fstrim timer enabled"
    else
        log_info "fstrim timer not available in this environment"
    fi
fi

# Disable NetworkManager-wait-online for faster boot
if systemctl list-unit-files | grep -q "NetworkManager-wait-online.service"; then
    log_info "Disabling NetworkManager-wait-online.service for faster boot"

    if sudo systemctl disable NetworkManager-wait-online.service 2>/dev/null; then
        log_success "NetworkManager-wait-online.service disabled (saves ~15-20s boot time)"
    else
        log_info "NetworkManager-wait-online.service already disabled"
    fi
else
    log_info "NetworkManager-wait-online.service not found"
fi

# CPU mitigations
disable_mitigations=$(get_config '.performance.disable_cpu_mitigations')

if [[ "$disable_mitigations" == "true" ]]; then
    log_warning "Disabling CPU mitigations (less secure but faster)"

    if confirm "This reduces security. Continue?"; then
        if cmd_exists grubby; then
            sudo grubby --update-kernel=ALL --args="mitigations=off"
            log_success "CPU mitigations disabled (requires reboot)"
        else
            log_info "grubby not available (container/no bootloader)"
        fi
    else
        log_info "Keeping CPU mitigations enabled"
    fi
fi

log_success "Performance optimizations applied"
