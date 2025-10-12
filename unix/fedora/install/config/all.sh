#!/bin/bash
# Apply all system configurations

log_section "System Configuration"

source "$FEDORA_INSTALL/config/system.sh"
source "$FEDORA_INSTALL/config/appimage.sh"
source "$FEDORA_INSTALL/config/firmware.sh"
source "$FEDORA_INSTALL/config/git.sh"
source "$FEDORA_INSTALL/config/services.sh"
source "$FEDORA_INSTALL/config/multimedia.sh"
source "$FEDORA_INSTALL/config/performance.sh"
source "$FEDORA_INSTALL/config/hardware/all.sh"
source "$FEDORA_INSTALL/config/nextdns.sh"
source "$FEDORA_INSTALL/config/secureboot.sh"

log_success "All system configurations applied"
