#!/bin/bash
# Rust toolchain installation and management

set -e

setup_rust() {
    local tools_json_key="${1:-.rust_tools}"

    echo "Setting up Rust toolchain"

    # Check if rustup is installed
    if command -v rustup &>/dev/null; then
        echo "[INFO] Rustup already installed"
        echo "[INFO] Updating Rust toolchain"
        rustup update stable
        rustup update nightly
    else
        echo "[INFO] Installing Rust via rustup"

        # Download and run rustup installer
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

        # Source cargo env
        if [[ -f "$HOME/.cargo/env" ]]; then
            source "$HOME/.cargo/env"
        fi

        # Install nightly toolchain
        rustup toolchain install nightly

        echo "[SUCCESS] Rust toolchain installed"
    fi

    # Add cargo to PATH for this session
    export PATH="$HOME/.cargo/bin:$PATH"

    echo "[SUCCESS] Rust toolchain setup completed"
}

install_rust_tools() {
    local tools_array=("$@")

    if [[ ${#tools_array[@]} -eq 0 ]]; then
        echo "[INFO] No Rust tools to install"
        return 0
    fi

    echo "Installing Rust tools"

    # Ensure cargo is available
    if ! command -v cargo &>/dev/null; then
        echo "[ERROR] cargo not found. Install Rust first with setup_rust"
        return 1
    fi

    # Add cargo bin to PATH
    export PATH="$HOME/.cargo/bin:$PATH"

    echo "[INFO] Installing ${#tools_array[@]} Rust tools"

    local installed=0
    local skipped=0
    local failed=0

    for tool in "${tools_array[@]}"; do
        # Check if tool is already installed
        if command -v "$tool" &>/dev/null || [[ -f "$HOME/.cargo/bin/$tool" ]]; then
            echo "[INFO] Already installed: $tool"
            skipped=$((skipped + 1))
        else
            echo "[INFO] Installing: $tool"
            if cargo install "$tool"; then
                echo "[SUCCESS] Installed: $tool"
                installed=$((installed + 1))
            else
                echo "[ERROR] Failed to install: $tool"
                failed=$((failed + 1))
            fi
        fi
    done

    echo ""
    echo "========================================="
    echo "Rust Tools Installation Summary"
    echo "========================================="
    echo "Installed: $installed"
    echo "Skipped: $skipped"
    echo "Failed: $failed"
    echo "========================================="

    echo "[SUCCESS] Rust tools installation completed"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_rust "$@"
fi
