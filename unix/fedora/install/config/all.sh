#!/bin/bash

set -eEuo pipefail

# Apply all system configurations

log_section "System Configuration"

source "$OMAFORGE_INSTALL/config/system.sh"
source "$OMAFORGE_INSTALL/config/appimage.sh"
source "$OMAFORGE_INSTALL/config/firmware.sh"
source "$OMAFORGE_INSTALL/config/git.sh"
source "$OMAFORGE_INSTALL/config/services.sh"
source "$OMAFORGE_INSTALL/config/multimedia.sh"
source "$OMAFORGE_INSTALL/config/performance.sh"
source "$OMAFORGE_INSTALL/config/hardware/all.sh"
source "$OMAFORGE_INSTALL/config/nextdns.sh"
source "$OMAFORGE_INSTALL/config/secureboot.sh"

log_success "All system configurations applied"
