#!/bin/bash
# System performance optimizations

echo "Applying performance optimizations"

# Configure zram
enable_zram=$(get_config '.performance.enable_zram')
zram_size=$(get_config '.performance.zram_size_mb')
enable_oomd=$(get_config '.performance.enable_oomd')
enable_fstrim=$(get_config '.performance.enable_fstrim')
disable_mitigations=$(get_config '.performance.disable_cpu_mitigations')
grub_timeout=$(get_config '.performance.grub_timeout')
auto_luks=$(get_config '.performance.auto_luks')
swappiness=$(get_config '.performance.swappiness')
shut_off_time=$(get_config '.performance.shut_off_time')

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

if [[ "$enable_oomd" == "true" ]]; then
    log_info "Enabling systemd-oomd (Out-of-Memory Daemon)"

    if sudo systemctl enable --now systemd-oomd 2>/dev/null; then
        log_success "systemd-oomd enabled"
    else
        log_info "systemd-oomd not available in this environment"
    fi
fi

if [[ "$enable_fstrim" == "true" ]]; then
    log_info "Enabling fstrim timer for SSD optimization"

    if sudo systemctl enable --now fstrim.timer 2>/dev/null; then
        log_success "fstrim timer enabled"
    else
        log_info "fstrim timer not available in this environment"
    fi
fi

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

# If grub_timeout is a valid integer
if [[ -v grub_timeout && "$grub_timeout" =~ ^[0-9]+$ ]]; then
    log_warning "Reducing GRUB timeout to 1 second"

    if confirm "This will reduce GRUB timeout. Continue?"; then
        if [ -f /etc/default/grub ] && sudo sed -i.bak "s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$grub_timeout/" /etc/default/grub; then
            grub_cfg=$( [ -d /boot/grub2 ] && echo "/boot/grub2/grub.cfg" || echo "/boot/grub/grub.cfg" )

            if [ -n "$grub_cfg" ] && sudo grub2-mkconfig -o "$grub_cfg"; then
                log_success "GRUB timeout reduced to 1 second"
            else
                log_warning "Failed to update GRUB configuration"
            fi
        else
            log_warning "Failed to modify /etc/default/grub or file not found"
        fi
    else
        log_warning "Operation cancelled by user"
    fi
else
    log_warning "grub_timeout is not set or not a valid integer"
fi

if [[ "$auto_luks" == "true" ]]; then
    log_warning "Setting up TPM2 auto-unlock for LUKS"

    if confirm "This will reduce security. Continue?"; then
        LUKS_DEVICE=$(lsblk -nlo NAME,FSTYPE | grep crypto_LUKS | awk '{print "/dev/"$1}')

        if [ -n "$LUKS_DEVICE" ]; then
            log_info "TPM2 device found, enrolling..."

            sudo systemd-cryptenroll "$LUKS_DEVICE" --tpm2-device=auto --tpm2-pcrs=0+1+7
            sudo dracut -f

            log_info "To rollback tpm2 auto-unlock, execute:\nsudo system-cryptenroll $LUKS_DEVICE --wipe-slot=tpm2\nsudo dracut -f"
        fi
    fi
fi

if [[ -v swappiness && "$swappiness" =~ ^[0-9]+$ ]]; then
    sudo tee /etc/sysctl.d/99-performance.conf > /dev/null <<EOF
net.ipv4.tcp_mtu_probing=1
vm.swappiness=${swappiness}
EOF
fi

if [[ -v shut_off_time && "$shut_off_time" =~ ^[0-9]+$ ]]; then
    sudo mkdir -p /etc/systemd/system.conf.d

    sudo tee /etc/systemd/system.conf.d/10-faster-shutdown.conf > /dev/null <<EOF
[Manager]
DefaultTimeoutStopSec=${shut_off_time}s
EOF
fi

sudo sysctl --system
sudo systemctl daemon-reload

log_success "Performance optimizations applied"
