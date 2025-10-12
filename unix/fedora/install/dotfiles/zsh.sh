#!/bin/bash
# ZSH configuration for Fedora
# Uses common Unix ZSH script

# Get ZSH configuration
zsh_dir=$(expand_path "$(get_config '.directories.zsh')")

# Source and run common ZSH setup
COMMON_SCRIPT="$FEDORA_PATH/../common/dotfiles/zsh.sh"

if [[ ! -f "$COMMON_SCRIPT" ]]; then
    log_error "Common ZSH script not found: $COMMON_SCRIPT"
    return 1
fi

# Source the common script
source "$COMMON_SCRIPT"

# Run ZSH setup
setup_zsh "$zsh_dir"
