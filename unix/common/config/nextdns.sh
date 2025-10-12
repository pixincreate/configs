#!/bin/bash

set -e

setup_nextdns() {
    local config_id="$1"

    echo "Configuring NextDNS"

    # Check if nextdns command exists
    if ! command -v nextdns &>/dev/null; then
        echo "[ERROR] nextdns command not found"
        echo "[INFO] Install nextdns first:"
        echo "  - macOS: brew install nextdns/tap/nextdns"
        echo "  - Fedora: sudo dnf install nextdns"
        echo "  - Debian: See https://nextdns.io/download"
        return 1
    fi

    if [[ -z "$config_id" ]]; then
        if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
            echo "[INFO] NON_INTERACTIVE mode: No NextDNS config ID provided, skipping"
            return 0
        fi

        echo "[INFO] Get your NextDNS configuration ID from: https://my.nextdns.io"
        read -p "Enter your NextDNS config ID (or press Enter to skip): " config_id

        if [[ -z "$config_id" ]]; then
            echo "[INFO] No NextDNS config ID provided, skipping"
            return 0
        fi
    fi

    if [[ ! "$config_id" =~ ^[a-zA-Z0-9]{6}$ ]]; then
        echo "[ERROR] Invalid NextDNS config ID format"
        echo "[ERROR] Expected format: 6 alphanumeric characters (e.g., abc123)"
        return 1
    fi

    echo "[INFO] Installing NextDNS with config ID: $config_id"

    if [[ $EUID -eq 0 ]]; then
        # Running as root
        nextdns install -config "$config_id" -report-client-info -auto-activate
    else
        if command -v sudo &>/dev/null; then
            sudo nextdns install -config "$config_id" -report-client-info -auto-activate
        else
            echo "[ERROR] This command requires root privileges"
            echo "[ERROR] Run as root or install sudo"
            return 1
        fi
    fi

    echo "[SUCCESS] NextDNS configured with ID: $config_id"
    echo "[INFO] NextDNS will start automatically on system boot"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_nextdns "$@"
fi
