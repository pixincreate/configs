#!/bin/bash
set -eEuo pipefail

# Migration: Set up LUKS Auto Unlock and reduce GRUB timeout to 1 second

echo "Running migration: Set up LUKS Auto Unlock and reduce GRUB timeout to 1 second"

confirm() {
    read -p "$1 [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

echo ""
echo "[1/3] Reducing GRUB timeout..."

if [[ -f /etc/default/grub ]]; then
    if confirm "This will reduce GRUB timeout to 1 second. Continue?"; then

        sudo cp /etc/default/grub /etc/default/grub.bak
        sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
        
        if [[ -d /boot/grub2 ]]; then
            grub_cfg="/boot/grub2/grub.cfg"
        else
            grub_cfg="/boot/grub/grub.cfg"
        fi
        
        if sudo grub2-mkconfig -o "$grub_cfg"; then
            echo "GRUB timeout reduced to 1 second"
        else
            echo "Failed to update GRUB configuration"
        fi
    else
        echo "Skipped GRUB timeout modification"
    fi
else
    echo "/etc/default/grub not found, skipping"
fi

echo ""
echo "[2/3] Setting up TPM2 auto-unlock for LUKS..."

LUKS_DEVICE=$(lsblk -nlo NAME,FSTYPE | grep crypto_LUKS | awk '{print "/dev/"$1}')

if [[ -z "$LUKS_DEVICE" ]]; then
    echo "No LUKS device found, skipping TPM2 setup"
elif [[ ! -e /dev/tpm0 ]]; then
    echo "TPM2 device not found, skipping"
else
    echo "Found LUKS device: $LUKS_DEVICE"
    echo "⚠  WARNING: This reduces security by auto-unlocking your encrypted drive"
    echo "   The drive will only unlock on this specific hardware with Secure Boot"
    
    if confirm "Continue with TPM2 enrollment?"; then
        echo "You will be asked for your LUKS passphrase..."
        
        if sudo systemd-cryptenroll "$LUKS_DEVICE" --tpm2-device=auto --tpm2-pcrs=0+1+7; then
            echo "TPM2 enrollment successful"
            
            echo "Rebuilding initramfs..."
            if sudo dracut -f; then
                echo "Initramfs rebuilt"
            else
                echo "Failed to rebuild initramfs"
            fi
            
            echo ""
            echo "To rollback TPM2 auto-unlock, run:"
            echo "  sudo systemd-cryptenroll $LUKS_DEVICE --wipe-slot=tpm2"
            echo "  sudo dracut -f"
        else
            echo "TPM2 enrollment failed"
        fi
    else
        echo "Skipped TPM2 enrollment"
    fi
fi

echo ""
echo "[3/3] Disabling CUPS service..."

service="cups.service"
if ! systemctl list-unit-files "$service" &>/dev/null; then
    echo "Service not available: $service"
    continue
fi

if systemctl is-enabled "$service" &>/dev/null; then
    echo "Disabling service: $service"
    sudo systemctl disable "$service" 2>/dev/null || echo "Failed to disable: $service"
else
    echo "Service already disabled: $service"
fi

echo ""
echo "Migration completed: LUKS Auto Unlock and GRUB timeout optimization"
echo "Changes will take effect after reboot"
