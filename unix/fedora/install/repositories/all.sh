#!/bin/bash
set -eEuo pipefail
# Setup all repositories

log_section "Repository Setup"

source "$OMAFORGE_INSTALL/repositories/rpmfusion.sh"
source "$OMAFORGE_INSTALL/repositories/copr.sh"
source "$OMAFORGE_INSTALL/repositories/terra.sh"
source "$OMAFORGE_INSTALL/repositories/external.sh"

# Refresh repository metadata
log_info "Refreshing repository metadata"
sudo dnf check-update -y || true

log_success "All repositories configured"
