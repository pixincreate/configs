#!/bin/bash
# Apply all system configurations

log_section "System Configuration"

source "$MACOS_INSTALL/config/system.sh"
source "$MACOS_INSTALL/config/git.sh"
source "$MACOS_INSTALL/config/nextdns.sh"

log_success "All system configurations applied"
