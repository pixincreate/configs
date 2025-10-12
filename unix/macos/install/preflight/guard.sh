#!/bin/bash
# Preflight checks for macOS setup

echo "Running preflight checks"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script is designed for macOS only"
    log_error "Detected OS: $OSTYPE"
    exit 1
fi

log_success "Running on macOS"

# Check for internet connectivity
if ! ping -c 1 -W 2 google.com &>/dev/null; then
    log_warning "No internet connection detected"

    if ! confirm "Continue anyway?"; then
        log_info "Setup cancelled"
        exit 1
    fi
else
    log_success "Internet connection available"
fi

# Check for Command Line Tools
if ! xcode-select -p &>/dev/null; then
    log_warning "Xcode Command Line Tools not installed"
    log_info "Installing Xcode Command Line Tools..."
    xcode-select --install

    log_info "Please complete the installation in the dialog box"
    log_info "Then re-run this script"
    exit 1
fi

log_success "Xcode Command Line Tools installed"

# Check for sufficient disk space (at least 10GB)
available_space=$(df -g / | tail -1 | awk '{print $4}')
if [[ $available_space -lt 10 ]]; then
    log_warning "Low disk space: ${available_space}GB available"
    log_warning "At least 10GB recommended"

    if ! confirm "Continue anyway?"; then
        log_info "Setup cancelled"
        exit 1
    fi
else
    log_success "Sufficient disk space: ${available_space}GB available"
fi

log_success "Preflight checks completed"
