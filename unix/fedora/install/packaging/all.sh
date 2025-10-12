#!/bin/bash
# Install all packages

log_section "Package Installation"

source "$FEDORA_INSTALL/packaging/base.sh"
source "$FEDORA_INSTALL/packaging/flatpak.sh"
source "$FEDORA_INSTALL/packaging/rust.sh"
source "$FEDORA_INSTALL/packaging/bloatware.sh"
source "$FEDORA_INSTALL/packaging/webapps.sh"

log_success "All packages installed"
