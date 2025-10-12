#!/bin/bash
# Homebrew package installation

set -e

install_brew_packages() {
    local package_file="$1"

    echo "Installing Homebrew packages"

    if [[ ! -f "$package_file" ]]; then
        echo "[ERROR] Package file not found: $package_file"
        return 1
    fi

    # Ensure Homebrew is installed
    if ! command -v brew &>/dev/null; then
        echo "[ERROR] Homebrew is not installed"
        return 1
    fi

    # Read packages from file
    local packages=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        packages+=("$line")
    done < "$package_file"

    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "[INFO] No packages to install"
        return 0
    fi

    echo "[INFO] Installing ${#packages[@]} packages"

    local installed=0
    local skipped=0
    local failed=0

    for package in "${packages[@]}"; do
        if brew list "$package" &>/dev/null; then
            echo "[INFO] Already installed: $package"
            skipped=$((skipped + 1))
        else
            echo "[INFO] Installing: $package"
            if brew install "$package"; then
                echo "[SUCCESS] Installed: $package"
                installed=$((installed + 1))
            else
                echo "[ERROR] Failed to install: $package"
                failed=$((failed + 1))
            fi
        fi
    done

    echo ""
    echo "========================================="
    echo "Homebrew Package Installation Summary"
    echo "========================================="
    echo "Installed: $installed"
    echo "Skipped: $skipped"
    echo "Failed: $failed"
    echo "========================================="

    echo "[SUCCESS] Homebrew package installation completed"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_brew_packages "$@"
fi
