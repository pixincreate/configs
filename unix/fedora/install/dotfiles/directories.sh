#!/bin/bash
# Directory creation for Fedora
# Uses common Unix directories script

# Source and run common directories setup
COMMON_SCRIPT="$OMAFORGE_PATH/../common/dotfiles/directories.sh"

if [[ ! -f "$COMMON_SCRIPT" ]]; then
    log_error "Common directories script not found: $COMMON_SCRIPT"
    return 1
fi

# Source the common script
source "$COMMON_SCRIPT"

# Run directory creation
create_directories
