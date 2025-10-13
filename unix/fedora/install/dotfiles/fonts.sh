#!/bin/bash
# Font installation for Fedora
# Uses common Unix fonts script

echo "Installing fonts"

# Get fonts configuration
fonts_source=$(expand_path "$(get_config '.dotfiles.fonts_source')")
fonts_target="$HOME/.local/share/fonts"

# Source and run common fonts setup
COMMON_SCRIPT="$OMAFORGE_PATH/../common/dotfiles/fonts.sh"

if [[ ! -f "$COMMON_SCRIPT" ]]; then
    log_error "Common fonts script not found: $COMMON_SCRIPT"
    return 1
fi

# Source the common script
source "$COMMON_SCRIPT"

# Run fonts installation
install_fonts "$fonts_source" "$fonts_target"
