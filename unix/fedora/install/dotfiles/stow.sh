#!/bin/bash

log_info "Managing dotfiles with Stow"

stow_dir=$(expand_path "$(get_config '.dotfiles.stow_source')")
target_dir="$HOME"
mapfile -t packages < <(get_config_array '.dotfiles.stow_packages')

# Source and run common stow setup
COMMON_SCRIPT="$OMAFORGE_PATH/../common/dotfiles/stow.sh"

if [[ ! -f "$COMMON_SCRIPT" ]]; then
    log_error "Common stow script not found: $COMMON_SCRIPT"
    return 1
fi

# Source the common script
source "$COMMON_SCRIPT"

# Run stow with Fedora config values
stow_dotfiles "$stow_dir" "$target_dir" "${packages[@]}"
