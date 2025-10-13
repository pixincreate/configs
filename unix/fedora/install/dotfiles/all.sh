#!/bin/bash
# Manage all dotfiles

log_section "Dotfiles Management"

source "$OMAFORGE_INSTALL/dotfiles/directories.sh"
source "$OMAFORGE_INSTALL/dotfiles/zsh.sh"
source "$OMAFORGE_INSTALL/dotfiles/stow.sh"
source "$OMAFORGE_INSTALL/dotfiles/fonts.sh"

log_success "Dotfiles management completed"
