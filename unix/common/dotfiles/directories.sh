#!/bin/bash

set -e

# Source platform detection helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/platform.sh"

create_directories() {
    echo "Creating directory structure"

    # Common directories for all Unix platforms
    local directories=(
        "$HOME/.config"
        "$HOME/.local/bin"
        "$HOME/.ssh"
        "$HOME/.zsh"
        "$HOME/Pictures"
        "$HOME/Pictures/Screenshots"
        "$HOME/Pictures/Wallpapers"
        "$HOME/Documents"
        "$HOME/Downloads"
        "$HOME/Dev"
    )

    local platform=$(detect_platform)
    case "$platform" in
        macos)
            directories+=("$HOME/Library/Fonts")
            ;;
        android)
            directories+=("$HOME/.rish")
            ;;
        *)
            directories+=("$HOME/.local/share/fonts")
            ;;
    esac

    echo "[INFO] Creating ${#directories[@]} directories"

    local created=0
    local existed=0

    for dir in "${directories[@]}"; do
        # Expand path
        dir=$(eval echo "$dir")

        if [[ -d "$dir" ]]; then
            echo "[INFO] Already exists: $dir"
            existed=$((existed + 1))
        else
            mkdir -p "$dir"
            echo "[SUCCESS] Created: $dir"
            created=$((created + 1))
        fi

        case "$(basename "$dir")" in
            .ssh)
                chmod 700 "$dir"
                echo "[INFO] Set permissions 700 for: $dir"
                ;;
            .config|.local)
                chmod 755 "$dir"
                ;;
        esac
    done

    echo ""
    echo "========================================="
    echo "Directory Creation Summary"
    echo "========================================="
    echo "Created: $created"
    echo "Existed: $existed"
    echo "========================================="

    echo "[SUCCESS] Directory structure created"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_directories "$@"
fi
