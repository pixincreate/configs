#!/bin/bash
# Preflight checks to validate environment
# Following Omarchy guard pattern

echo "Validating system requirements"

# Check if running on Fedora
if [[ ! -f /etc/fedora-release ]]; then
    log_error "This script is designed for Fedora Linux only"
    exit 1
fi

log_success "Running on Fedora Linux"

# Check if user is not root
if [[ $EUID -eq 0 ]]; then
    # Detect if in container
    if [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]]; then
        log_warning "Running as root (container environment detected)"
    else
        log_error "DO NOT run this script as root on systems"
        log_error "The script uses sudo for privileged operations"
        log_error "Run as a regular user: ./fedora-setup"
        exit 1
    fi
else
    log_success "Running as non-root user: $USER"
fi

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" ]]; then
    log_warning "This script is designed for x86_64 architecture"
    log_warning "Current architecture: $ARCH"

    if ! confirm "Continue anyway?"; then
        log_info "Setup cancelled"
        exit 1
    fi
else
    log_success "Running on x86_64 architecture"
fi

# Check for sudo access (skip if root)
if [[ $EUID -ne 0 ]]; then
    if ! sudo -v &>/dev/null; then
        log_error "User $USER does not have sudo privileges"
        exit 1
    fi
    log_success "User has sudo privileges"
fi

# Check internet connectivity
if ! ping -c 1 1.1.1.1 &>/dev/null; then
    log_error "No internet connectivity detected"
    log_error "Setup requires internet connection to download packages"
    exit 1
else
    log_success "Internet connectivity verified"
fi

log_success "All preflight checks passed"
