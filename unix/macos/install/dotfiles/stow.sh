#!/bin/bash
# GNU Stow dotfiles deployment for macOS

echo "Deploying dotfiles with GNU Stow"

# Get stow configuration
stow_dir=$(expand_path "$(get_config '.dotfiles.stow_source')")
target_dir="$HOME"
mapfile -t packages < <(get_config_array '.dotfiles.stow_packages')

# Source common stow script
COMMON_SCRIPT="$MACOS_PATH/../common/dotfiles/stow.sh"

if [[ ! -f "$COMMON_SCRIPT" ]]; then
    log_error "Common stow script not found: $COMMON_SCRIPT"
    return 1
fi

source "$COMMON_SCRIPT"

# Run stow with macOS config values
stow_dotfiles "$stow_dir" "$target_dir" "${packages[@]}"
