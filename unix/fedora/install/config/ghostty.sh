#!/bin/bash

# Set up Ghostty OS-specific configuration symlink

GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
GHOSTTY_OS_DIR="$GHOSTTY_CONFIG_DIR/os"

if [ ! -d "$GHOSTTY_OS_DIR" ]; then
    echo "Ghostty config directory not found at $GHOSTTY_OS_DIR"
    exit 0
fi

# Detect OS and create appropriate symlink
if [ -f "$GHOSTTY_OS_DIR/current.conf" ]; then
    echo "Ghostty OS config already linked"
    exit 0
fi

if [ "$(uname)" = "Darwin" ]; then
    # macOS
    ln -sf macos.conf "$GHOSTTY_OS_DIR/current.conf"
    echo "Linked Ghostty config to macOS"
elif [ "$(uname)" = "Linux" ]; then
    # Linux
    ln -sf linux.conf "$GHOSTTY_OS_DIR/current.conf"
    echo "Linked Ghostty config to Linux"
else
    echo "Unknown OS, skipping Ghostty config linking"
    exit 0
fi
