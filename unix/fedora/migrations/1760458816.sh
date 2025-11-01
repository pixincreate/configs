#!/bin/bash
set -eEuo pipefail

# Migration: Remove `--incognito` flag from existing webapp desktop files

echo "Removing --incognito flag from existing webapp desktop files"

DESKTOP_DIR="$HOME/.local/share/applications"

if [[ ! -d "$DESKTOP_DIR" ]]; then
    echo "[INFO] Desktop applications directory not found, nothing to migrate"
    exit 0
fi

declare -i updated=0

for desktop_file in "$DESKTOP_DIR"/*.desktop; do
    [[ -f "$desktop_file" ]] || continue

    if grep -q "omaforge-launch-webapp.*--incognito" "$desktop_file" 2>/dev/null; then
        # Check if already fixed
        if ! grep -q "omaforge-launch-webapp.*--incognito" "$desktop_file" 2>/dev/null; then
            echo "[INFO] Already fixed: $(basename "$desktop_file")"
            continue
        fi

        echo "[INFO] Updating: $(basename "$desktop_file")"

        # Backup before modification
        cp "$desktop_file" "${desktop_file}.bak"

        # Remove --incognito flag
        if sed -i 's/\(omaforge-launch-webapp[^"]*\) --incognito/\1/' "$desktop_file"; then
            updated=$((updated + 1))
        else
            echo "[WARNING] Failed to update: $(basename "$desktop_file")"
            # Restore backup
            mv "${desktop_file}.bak" "$desktop_file"
        fi
    fi
done

echo "[SUCCESS] Migration completed: Updated $updated desktop files"
