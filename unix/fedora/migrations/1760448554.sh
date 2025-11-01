#!/bin/bash
set -eEuo pipefail

# Migration: Fix webapp desktop files to use absolute paths

echo "Fixing webapp desktop files"

OMAFORGE_BIN="$HOME/Dev/.configs/unix/fedora/bin"
DESKTOP_DIR="$HOME/.local/share/applications"

# Validate paths
if [[ ! -d "$OMAFORGE_BIN" ]]; then
    echo "[ERROR] Omaforge bin directory not found: $OMAFORGE_BIN"
    exit 1
fi

if [[ ! -d "$DESKTOP_DIR" ]]; then
    echo "[INFO] Desktop applications directory not found, nothing to migrate"
    exit 0
fi

# Track changes
declare -i fixed=0

# Fix all desktop files that use omaforge-launch-webapp without full path
for desktop_file in "$DESKTOP_DIR"/*.desktop; do
    [[ -f "$desktop_file" ]] || continue

    # Check if file uses relative path to omaforge-launch-webapp
    if grep -q "^Exec=omaforge-launch-webapp " "$desktop_file" 2>/dev/null; then
        # Check if already fixed
        if grep -q "^Exec=$OMAFORGE_BIN/omaforge-launch-webapp " "$desktop_file" 2>/dev/null; then
            echo "[INFO] Already fixed: $(basename "$desktop_file")"
            continue
        fi

        echo "[INFO] Fixing: $(basename "$desktop_file")"

        # Backup before modification
        cp "$desktop_file" "${desktop_file}.bak"

        # Use more precise sed
        if sed -i "s|^Exec=omaforge-launch-webapp |Exec=$OMAFORGE_BIN/omaforge-launch-webapp |" "$desktop_file"; then
            fixed=$((fixed + 1))
        else
            echo "[WARNING] Failed to fix: $(basename "$desktop_file")"
            # Restore backup
            mv "${desktop_file}.bak" "$desktop_file"
        fi
    fi
done

echo "[SUCCESS] Migration completed: Fixed $fixed webapp desktop files"
