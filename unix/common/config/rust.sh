#!/bin/bash
# Rust toolchain installation and management

set -e

setup_rust() {
    local tools_json_key="${1:-.rust_tools}"

    echo "Setting up Rust toolchain"

    # Check if rustup is installed
    if command -v rustup &>/dev/null; then
        echo "[INFO] Rust is already installed, updating..."
        rustup update
    else
        echo "[INFO] Installing Rust with rustup-init..."

        # Run rustup-init (assumes rustup was installed via package manager)
        rustup-init -y --default-toolchain stable

        # Add cargo to PATH for the current process
        local cargo_bin="$HOME/.cargo/bin"
        if [[ ! "$PATH" =~ $cargo_bin ]]; then
            export PATH="$cargo_bin:$PATH"
        fi

        # Now rustup should be available
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
