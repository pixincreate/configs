#!/bin/bash
set -eEuo pipefail

# Migration: Install Topgrade

echo "Running migration: Install Topgrade"

# Check if already installed (idempotency)
if rpm -q topgrade &>/dev/null; then
    echo "[INFO] Topgrade already installed, skipping"
    exit 0
fi

# Use the package manager command
if ! omaforge-pkg-add topgrade; then
    echo "[ERROR] Failed to install Topgrade"
    exit 1
fi

echo "[SUCCESS] Migration completed: Topgrade has been installed"
