#!/bin/bash

set -e

stow_dotfiles() {
    local stow_dir="${1:-$HOME/Dev/.configs/home}"
    local target_dir="${2:-$HOME}"
    shift 2
    local packages=("$@")

    echo "Deploying dotfiles with GNU Stow"

    if ! command -v stow &>/dev/null; then
        echo "[ERROR] GNU Stow is not installed"
        echo "[INFO] Install stow:"
        echo "  - macOS: brew install stow"
        echo "  - Fedora: sudo dnf install stow"
        echo "  - Debian: sudo apt install stow"
        echo "  - Android: pkg install stow"
        return 1
    fi

    if [[ ! -d "$stow_dir" ]]; then
        echo "[ERROR] Stow directory not found: $stow_dir"
        return 1
    fi

    if [[ ${#packages[@]} -eq 0 ]]; then
        packages=("cargo" "config" "git" "ssh" "zsh" "Pictures" "local")
        echo "[INFO] Using default packages: ${packages[*]}"
    fi

    echo "[INFO] Stow directory: $stow_dir"
    echo "[INFO] Target directory: $target_dir"
    echo "[INFO] Packages to stow: ${packages[*]}"
    echo ""

    local success_count=0
    local skip_count=0
    local conflict_count=0

    for package in "${packages[@]}"; do
        local package_dir="$stow_dir/$package"

        if [[ ! -d "$package_dir" ]]; then
            echo "[WARNING] Package directory not found: $package"
            skip_count=$((skip_count + 1))
            continue
        fi

        echo "[INFO] Stowing package: $package"

        # Try to stow with --no-folding (safer, preserves directory structure)
        if stow --dir="$stow_dir" --target="$target_dir" --restow --no-folding "$package" 2>&1 | tee /tmp/stow-error.log | grep -qi "conflict"; then
            echo "[WARNING] Conflicts detected for: $package"
            cat /tmp/stow-error.log

            if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
                echo "[INFO] NON_INTERACTIVE mode: Auto-adopting and restowing $package"
                REPLY="y"
            else
                read -p "Adopt existing files and restow $package? (WARNING: Overwrites stow directory) [y/N] " -n 1 -r
                echo
            fi

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Create backup before adopting
                local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
                mkdir -p "$backup_dir"
                echo "[INFO] Creating backup at: $backup_dir"

                # Backup conflicting files
                while IFS= read -r line; do
                    if [[ "$line" =~ "existing target is" ]]; then
                        local file=$(echo "$line" | awk '{print $NF}')
                        if [[ -f "$target_dir/$file" ]]; then
                            mkdir -p "$backup_dir/$(dirname "$file")"
                            cp "$target_dir/$file" "$backup_dir/$file"
                        fi
                    fi
                done < /tmp/stow-error.log

                stow --dir="$stow_dir" --target="$target_dir" --adopt "$package"
                echo "[SUCCESS] Adopted and stowed: $package"
                success_count=$((success_count + 1))
            else
                echo "[INFO] Skipped: $package"
                skip_count=$((skip_count + 1))
            fi
            conflict_count=$((conflict_count + 1))
        else
            echo "[SUCCESS] Stowed: $package"
            success_count=$((success_count + 1))
        fi
    done

    rm -f /tmp/stow-error.log

    echo ""
    echo "========================================="
    echo "Stow Deployment Summary"
    echo "========================================="
    echo "Success: $success_count"
    echo "Skipped: $skip_count"
    echo "Conflicts: $conflict_count"
    echo "========================================="

    echo "[SUCCESS] Dotfiles deployment completed"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    stow_dotfiles "$@"
fi
