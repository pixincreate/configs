#!/bin/bash
# Logging functions for Fedora setup
# No emojis, professional output following Omarchy standards

log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[SUCCESS] $1"
}

log_warning() {
    echo "[WARNING] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

log_section() {
    echo ""
    echo "=== $1 ==="
    echo ""
}

log_header() {
    echo ""
    echo "================================================================================"
    echo "$1"
    echo "================================================================================"
    echo ""
}
