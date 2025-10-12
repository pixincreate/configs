#!/bin/bash
# Font installation for macOS

# Source common fonts script
COMMON_SCRIPT="$MACOS_PATH/../common/dotfiles/fonts.sh"

if [[ ! -f "$COMMON_SCRIPT" ]]; then
    log_error "Common fonts script not found: $COMMON_SCRIPT"
    return 1
fi

source "$COMMON_SCRIPT"

# Run font installation
install_fonts
