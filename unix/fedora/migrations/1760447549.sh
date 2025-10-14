#!/bin/bash
# Migration: Clean up rustup modifications to shell configs
# Removes any `. "$HOME/.cargo/env"` lines that rustup may have added

echo "Cleaning up rustup shell modifications"

# Check and clean ~/.zshenv
if [[ -f "$HOME/.zshenv" ]]; then
    if grep -q '^\. "$HOME/\.cargo/env"' "$HOME/.zshenv" 2>/dev/null; then
        echo "Removing rustup modifications from ~/.zshenv"
        sed -i.bak '/^\. "$HOME\/\.cargo\/env"/d' "$HOME/.zshenv"
        echo "Backup saved to ~/.zshenv.bak"
    fi
fi

# Check and clean ~/.bashrc
if [[ -f "$HOME/.bashrc" ]]; then
    if grep -q '^\. "$HOME/\.cargo/env"' "$HOME/.bashrc" 2>/dev/null; then
        echo "Removing rustup modifications from ~/.bashrc"
        sed -i.bak '/^\. "$HOME\/\.cargo\/env"/d' "$HOME/.bashrc"
        echo "Backup saved to ~/.bashrc.bak"
    fi
fi

# Check and clean ~/.profile
if [[ -f "$HOME/.profile" ]]; then
    if grep -q '^\. "$HOME/\.cargo/env"' "$HOME/.profile" 2>/dev/null; then
        echo "Removing rustup modifications from ~/.profile"
        sed -i.bak '/^\. "$HOME\/\.cargo\/env"/d' "$HOME/.profile"
        echo "Backup saved to ~/.profile.bak"
    fi
fi

echo "Migration completed: Rustup shell modifications cleaned"
