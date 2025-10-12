#!/bin/bash
# Install Rust toolchain and tools for macOS

echo "Setting up Rust"

# Source common Rust setup
COMMON_SCRIPT="$MACOS_PATH/../common/config/rust.sh"

if [[ ! -f "$COMMON_SCRIPT" ]]; then
    log_error "Common Rust script not found: $COMMON_SCRIPT"
    return 1
fi

source "$COMMON_SCRIPT"

# Setup Rust toolchain
setup_rust

# Get Rust tools from config
mapfile -t tools < <(get_config_array '.rust.tools')

if [[ ${#tools[@]} -eq 0 ]]; then
    log_info "No Rust tools configured"
    return 0
fi

# Install Rust tools
install_rust_tools "${tools[@]}"

log_success "Rust setup completed"
