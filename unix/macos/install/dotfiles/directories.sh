#!/bin/bash
# Directory creation for macOS

# Source common directories script
COMMON_SCRIPT="$MACOS_PATH/../common/dotfiles/directories.sh"

if [[ ! -f "$COMMON_SCRIPT" ]]; then
    log_error "Common directories script not found: $COMMON_SCRIPT"
    return 1
fi

source "$COMMON_SCRIPT"

# Run directory creation
create_directories
