#!/bin/bash
# Setup Terra repository for modern packages (Zed, etc.)

echo "Setting up Terra repository"

enabled=$(get_config '.repositories.terra.enabled')

if [[ "$enabled" != "true" ]]; then
    log_info "Terra repository disabled in config, skipping"
    return 0
fi

if pkg_installed terra-release; then
    log_info "Terra repository already installed"
    return 0
fi

log_info "Installing Terra repository"

sudo dnf install -y \
    --nogpgcheck \
    --repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" \
    terra-release

log_success "Terra repository installed"
