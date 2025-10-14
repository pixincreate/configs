#!/bin/bash
# Migration: Remove `--incognito` flag from existing webapp desktop files

echo "Removing --incognito flag from existing webapp desktop files"

DESKTOP_DIR="$HOME/.local/share/applications"

if [[ -d "$DESKTOP_DIR" ]]; then
    for desktop_file in "$DESKTOP_DIR"/*.desktop; do
        [[ -f "$desktop_file" ]] || continue

        if grep -q "omaforge-launch-webapp.*--incognito" "$desktop_file" 2>/dev/null; then
            echo "  Updating: $(basename "$desktop_file")"
            sed -i.bak 's/\(omaforge-launch-webapp[^"]*\) --incognito/\1/' "$desktop_file"
        fi
    done
fi

echo "Migration completed: --incognito flag has been removed from existing setup successfully"
