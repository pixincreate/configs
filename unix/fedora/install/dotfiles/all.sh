#!/bin/bash
# Manage all dotfiles

log_section "Dotfiles Management"

source "$FEDORA_INSTALL/dotfiles/directories.sh"
source "$FEDORA_INSTALL/dotfiles/stow.sh"
source "$FEDORA_INSTALL/dotfiles/fonts.sh"
source "$FEDORA_INSTALL/dotfiles/zsh.sh"

log_success "Dotfiles management completed"
