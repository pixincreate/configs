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

# Check env var or prompt
if [[ "${OMAFORGE_SECUREBOOT:-false}" == "true" ]]; then
    log_info "OMAFORGE_SECUREBOOT=true: Proceeding"
elif ! confirm "Setup Secure Boot support?"; then
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
    if ! confirm "Re-enroll MOK key?"; then
        log_info "Skipped MOK enrollment"
        log_success "Secure Boot setup completed"
        return 0
    fi
fi

echo ""
log_info "MOK (Machine Owner Key) Enrollment"
echo "-------------------------------------------------------------------"
log_info "You will be prompted to create a MOK enrollment password."
log_info "This password is temporary and only used once during next boot."
log_info "Requirements: 8-256 characters (use a simple memorable password)"
log_info "Example: 'temporary123'"
echo "-------------------------------------------------------------------"
echo ""

if confirm "Enroll MOK key now?"; then
    log_info "Running: sudo mokutil --import /etc/pki/akmods/certs/public_key.der"
    if sudo mokutil --import /etc/pki/akmods/certs/public_key.der; then
        echo ""
        log_success "MOK key enrollment initiated"
        echo ""
        log_warning "IMPORTANT: Reboot required to complete enrollment"
        echo "-------------------------------------------------------------------"
        log_info "After reboot, MOK Manager will appear (blue screen):"
        log_info "  1. Select 'Enroll MOK'"
        log_info "  2. Select 'Continue'"
        log_info "  3. Select 'Yes'"
        log_info "  4. Enter the password you just created"
        log_info "  5. Select 'Reboot'"
        echo "-------------------------------------------------------------------"
    else
        log_error "MOK enrollment failed"
        return 1
    fi
else
    log_info "MOK enrollment skipped"
    echo ""
    log_info "To enroll manually later, run:"
    echo "  sudo mokutil --import /etc/pki/akmods/certs/public_key.der"
fi

log_success "Secure Boot setup completed"
