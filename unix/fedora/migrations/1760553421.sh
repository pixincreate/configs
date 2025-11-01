#!/bin/bash
set -eEuo pipefail

# Migration: Install trash-cli

echo "Running migration: Install trash-cli"

# Check if already installed (idempotency)
if rpm -q trash-cli &>/dev/null; then
    echo "[INFO] trash-cli already installed, skipping"
    exit 0
fi

if ! omaforge-pkg-add trash-cli; then
    echo "[ERROR] Failed to install trash-cli"
    exit 1
fi

echo "[SUCCESS] Migration completed: trash-cli has been installed"
