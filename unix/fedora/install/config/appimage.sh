#!/bin/bash
# Setup AppImage support with FUSE

echo "Setting up AppImage support"

# Check if FUSE is already installed
if pkg_installed fuse; then
    log_info "FUSE already installed"
    return 0
fi

log_info "Installing FUSE for AppImage support"
sudo dnf install -y fuse

log_success "FUSE installed for AppImage support"
