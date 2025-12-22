#!/bin/bash
# Install Rust toolchain and tools for Fedora

echo "Setting up Rust"

# Source common Rust setup
COMMON_SCRIPT="$OMAFORGE_PATH/../common/config/rust.sh"

if [[ ! -f "$COMMON_SCRIPT" ]]; then
    log_error "Common Rust script not found: $COMMON_SCRIPT"
    return 1
fi

source "$COMMON_SCRIPT"

# Setup Rust toolchain
setup_rust

# Read Rust tools from package file
pkg_file="$OMAFORGE_PATH/packages/rust.packages"

if [[ ! -f "$pkg_file" ]]; then
    log_info "No Rust tools configured"
    return 0
fi

mapfile -t tools < <(grep -v '^#' "$pkg_file" | grep -v '^$')

if [[ ${#tools[@]} -eq 0 ]]; then
    log_info "No Rust tools configured"
    return 0
fi

# Install Rust tools
install_rust_tools "${tools[@]}"

log_success "Rust setup completed"
