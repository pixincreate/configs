#!/bin/bash
# Setup RPM Fusion repositories (free and nonfree)

echo "Setting up RPM Fusion repositories"

enabled=$(get_config '.repositories.rpmfusion.enabled')

if [[ "$enabled" != "true" ]]; then
    log_info "RPM Fusion disabled in config, skipping"
    return 0
fi

if pkg_installed rpmfusion-free-release; then
    log_info "RPM Fusion already installed"
    return 0
fi

log_info "Installing RPM Fusion free and nonfree repositories"

sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

log_success "RPM Fusion repositories installed"
