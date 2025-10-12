#!/bin/bash
# Setup Secure Boot support for NVIDIA and other kernel modules

echo "Configuring Secure Boot support"

# Skip in containers or systems without EFI
if [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]] || ! [[ -d /sys/firmware/efi ]]; then
    log_info "Secure Boot setup skipped"
    return 0
fi

log_info "Secure Boot setup is optional and required only if:"
log_info "  - You have Secure Boot enabled in BIOS/UEFI"
log_info "  - You installed NVIDIA drivers or other third-party kernel modules"

if ! confirm "Setup Secure Boot support?"; then
    log_info "Skipped Secure Boot setup"
    return 0
fi

# Install required packages
log_info "Installing Secure Boot packages"
sudo dnf install -y kmodtool akmods mokutil openssl

# Generate kernel module certificate
log_info "Generating kernel module signing certificate"
if sudo kmodgenca -a; then
    log_success "Kernel module certificate generated"
else
    log_warning "Failed to generate certificate"
    return 1
fi

# Check if key is already enrolled
if sudo mokutil --list-enrolled 2>/dev/null | grep -q "public_key.der"; then
    log_info "MOK key may already be enrolled"
fi

# Display manual enrollment instructions
echo ""
log_warning "MOK (Machine Owner Key) Enrollment Required"
echo "-------------------------------------------------------------------"
log_info "The setup has generated a signing certificate, but enrollment"
log_info "requires an interactive password prompt that cannot be automated."
echo ""
log_info "To complete Secure Boot setup, run this command manually:"
echo ""
echo "  sudo mokutil --import /etc/pki/akmods/certs/public_key.der"
echo ""
log_info "You will be prompted to create a MOK enrollment password."
log_info "This password is temporary and only used once during next boot."
log_info "Requirements: 8-256 characters (use a simple memorable password)"
echo ""
log_info "After running the command:"
log_info "  1. Reboot your system"
log_info "  2. MOK Manager will appear during boot"
log_info "  3. Select 'Enroll MOK'"
log_info "  4. Select 'Continue'"
log_info "  5. Select 'Yes'"
log_info "  6. Enter the password you just created"
log_info "  7. Reboot"
echo "-------------------------------------------------------------------"
echo ""

if confirm "Open manual enrollment instructions in less?"; then
    cat << 'EOF' | less
Secure Boot MOK Enrollment Instructions
========================================

1. Run the enrollment command:
   $ sudo mokutil --import /etc/pki/akmods/certs/public_key.der

2. Create a MOK password when prompted (8-256 characters)
   - Use a simple password you can remember for one reboot
   - Example: "temporary123"

3. Reboot your system:
   $ sudo reboot

4. During boot, MOK Manager will appear (blue screen):
   - Select "Enroll MOK"
   - Select "Continue"
   - Select "Yes"
   - Enter the password you created in step 2
   - Select "Reboot"

5. After reboot, verify enrollment:
   $ sudo mokutil --list-enrolled

Your NVIDIA drivers and other kernel modules will now work with Secure Boot.
EOF
fi

log_success "Secure Boot setup completed (manual enrollment required)"
