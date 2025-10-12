#!/bin/bash
# ZSH configuration for macOS

# Get ZSH configuration
zsh_dir=$(expand_path "$(get_config '.directories.zsh')")

# Source common ZSH script
COMMON_SCRIPT="$MACOS_PATH/../common/dotfiles/zsh.sh"

if [[ ! -f "$COMMON_SCRIPT" ]]; then
    log_error "Common ZSH script not found: $COMMON_SCRIPT"
    return 1
fi

source "$COMMON_SCRIPT"

# Run ZSH setup
setup_zsh "$zsh_dir"
