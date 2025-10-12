#!/bin/bash
# Install all packages

log_section "Package Installation"

source "$MACOS_INSTALL/packaging/homebrew.sh"
source "$MACOS_INSTALL/packaging/brew.sh"
source "$MACOS_INSTALL/packaging/cask.sh"
source "$MACOS_INSTALL/packaging/rust.sh"

log_success "All packages installed"
