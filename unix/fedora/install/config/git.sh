#!/bin/bash
# Git and SSH configuration for Fedora
# Uses common Unix git setup script

# Get configuration from Fedora config.json
git_name=$(get_config '.git.user_name')
git_email=$(get_config '.git.user_email')
ssh_dir=$(expand_path "$(get_config '.directories.ssh')")
gitconfig_local="$HOME/.config/gitconfig/.gitconfig.local"

# Source and run common git setup
COMMON_SCRIPT="$OMAFORGE_PATH/../common/config/git.sh"

if [[ ! -f "$COMMON_SCRIPT" ]]; then
    log_error "Common git setup script not found: $COMMON_SCRIPT"
    return 1
fi

# Source the common script
source "$COMMON_SCRIPT"

# Run setup with Fedora-specific config values
setup_git "$git_name" "$git_email" "$ssh_dir" "$gitconfig_local"
