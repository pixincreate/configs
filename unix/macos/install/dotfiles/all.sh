#!/bin/bash
# Manage all dotfiles

log_section "Dotfiles Management"

source "$MACOS_INSTALL/dotfiles/directories.sh"
source "$MACOS_INSTALL/dotfiles/stow.sh"
source "$MACOS_INSTALL/dotfiles/fonts.sh"
source "$MACOS_INSTALL/dotfiles/zsh.sh"

log_success "Dotfiles management completed"
