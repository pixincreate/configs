#!/bin/bash
set -eEuo pipefail
# Install all packages

log_section "Package Installation"

source "$OMAFORGE_INSTALL/packaging/base.sh"
source "$OMAFORGE_INSTALL/packaging/flatpak.sh"
source "$OMAFORGE_INSTALL/packaging/rust.sh"
source "$OMAFORGE_INSTALL/packaging/bloatware.sh"
source "$OMAFORGE_INSTALL/packaging/webapps.sh"

log_success "All packages installed"
