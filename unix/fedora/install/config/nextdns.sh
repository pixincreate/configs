#!/bin/bash

# Check if nextdns is installed
if ! cmd_exists nextdns; then
    log_info "NextDNS not installed, installing from repository"
    sudo dnf install -y nextdns || {
        log_error "Failed to install nextdns"
        return 1
    }
fi

# Source and run common nextdns setup
COMMON_SCRIPT="$FEDORA_PATH/../common/config/nextdns.sh"

if [[ ! -f "$COMMON_SCRIPT" ]]; then
    log_error "Common nextdns setup script not found: $COMMON_SCRIPT"
    return 1
fi

# Source the common script
source "$COMMON_SCRIPT"

# Run setup (will prompt for config ID if not provided)
setup_nextdns
