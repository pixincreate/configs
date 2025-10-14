#!/bin/bash
# Migration: Fix webapp desktop files to use absolute paths

echo "Fixing webapp desktop files"

OMAFORGE_BIN="$HOME/Dev/.configs/unix/fedora/bin"
DESKTOP_DIR="$HOME/.local/share/applications"

# Fix all desktop files that use omaforge-launch-webapp without full path
for desktop_file in "$DESKTOP_DIR"/*.desktop; do
    [[ -f "$desktop_file" ]] || continue

    # Check if file uses relative path to omaforge-launch-webapp
    if grep -q "^Exec=omaforge-launch-webapp " "$desktop_file" 2>/dev/null; then
        echo "Fixing: $(basename "$desktop_file")"
        sed -i.bak "s|^Exec=omaforge-launch-webapp |Exec=$OMAFORGE_BIN/omaforge-launch-webapp |" "$desktop_file"
    fi
done

echo "Migration completed: Webapp desktop files fixed"
