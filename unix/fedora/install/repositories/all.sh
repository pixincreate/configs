#!/bin/bash
# Setup all repositories

log_section "Repository Setup"

source "$FEDORA_INSTALL/repositories/rpmfusion.sh"
source "$FEDORA_INSTALL/repositories/copr.sh"
source "$FEDORA_INSTALL/repositories/terra.sh"
source "$FEDORA_INSTALL/repositories/external.sh"

# Refresh repository metadata
log_info "Refreshing repository metadata"
sudo dnf check-update -y || true

log_success "All repositories configured"
