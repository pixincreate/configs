#!/bin/bash

set -e

stow_dotfiles() {
    local stow_dir="${1:-$HOME/Dev/.configs/home}"
    local target_dir="${2:-$HOME}"
    shift 2
    local packages=("$@")

    echo "Managing dotfiles with Stow"

    if ! command -v stow &>/dev/null; then
        echo "[ERROR] GNU Stow is not installed"
        echo "[INFO] Install stow:"
        echo "  - macOS: brew install stow"
        echo "  - Fedora: sudo dnf install stow"
        return 1
    fi

    if [[ ! -d "$stow_dir" ]]; then
        echo "[ERROR] Stow directory not found: $stow_dir"
        return 1
    fi

    for pkg in "${packages[@]}"; do
        pkg_dir="$stow_dir/$pkg"

        if [[ ! -d "$pkg_dir" ]]; then
            echo "[WARNING] Package directory not found: $pkg_dir"
            continue
        fi

        echo "[INFO] Stowing package: $pkg"

        if stow --no-folding --restow --dir="$stow_dir" --target="$target_dir" "$pkg"; then
            echo "[SUCCESS] Successfully stowed: $pkg"
        else
            if confirm "Stow conflict detected for $pkg. Override existing files?"; then
                stow --no-folding --restow --adopt --dir="$stow_dir" --target="$target_dir" "$pkg"
                echo "[SUCCESS] Successfully stowed with override: $pkg"
            else
                echo "[WARNING] Skipped stowing: $pkg"
            fi
        fi
    done

    echo "[SUCCESS] Dotfiles stowing completed"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    stow_dotfiles "$@"
fi
