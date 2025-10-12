#!/bin/bash

set -e

# Source platform detection helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/platform.sh"

install_fonts() {
    local fonts_source="${1:-$HOME/Dev/.configs/fonts}"
    local fonts_target="$2"

    echo "Installing fonts"

    if [[ -z "$fonts_target" ]]; then
        local platform=$(detect_platform)
        if [[ "$platform" == "macos" ]]; then
            fonts_target="$HOME/Library/Fonts"
        else
            fonts_target="$HOME/.local/share/fonts"
        fi
        echo "[INFO] Auto-detected fonts directory: $fonts_target"
    fi

    if [[ ! -d "$fonts_source" ]]; then
        echo "[ERROR] Fonts source directory not found: $fonts_source"
        return 1
    fi

    mkdir -p "$fonts_target"

    # Count fonts
    local font_count=$(find "$fonts_source" -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.TTF" -o -name "*.OTF" \) 2>/dev/null | wc -l)

    if [[ $font_count -eq 0 ]]; then
        echo "[WARNING] No fonts found in: $fonts_source"
        return 0
    fi

    echo "[INFO] Found $font_count fonts in: $fonts_source"
    echo "[INFO] Installing to: $fonts_target"

    local installed=0
    local skipped=0

    find "$fonts_source" -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.TTF" -o -name "*.OTF" \) 2>/dev/null | while read -r font; do
        local font_name=$(basename "$font")
        local target_path="$fonts_target/$font_name"

        if [[ -f "$target_path" ]]; then
            echo "[INFO] Already installed: $font_name"
            ((skipped++))
        else
            cp "$font" "$target_path"
            echo "[SUCCESS] Installed: $font_name"
            ((installed++))
        fi
    done

    echo "[INFO] Rebuilding font cache"

    local platform=$(detect_platform)
    if command -v fc-cache &>/dev/null; then
        fc-cache -f "$fonts_target"
        echo "[SUCCESS] Font cache rebuilt"
    elif [[ "$platform" == "macos" ]]; then
        # macOS doesn't need manual cache rebuild
        echo "[INFO] macOS will rebuild font cache automatically"
    else
        echo "[WARNING] fc-cache not found, fonts may not be immediately available"
        echo "[INFO] Install fontconfig: sudo dnf install fontconfig (Fedora) or sudo apt install fontconfig (Debian)"
    fi

    echo "[SUCCESS] Font installation completed"
    echo "[INFO] Installed: $installed, Skipped: $skipped"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_fonts "$@"
fi
