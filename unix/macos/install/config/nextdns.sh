#!/bin/bash
# NextDNS configuration for macOS

echo "Configuring NextDNS"

# Check if nextdns is installed via Homebrew
if ! cmd_exists nextdns; then
    log_info "NextDNS not installed, installing via Homebrew"
    brew install nextdns/tap/nextdns || {
        log_error "Failed to install nextdns"
        return 1
    }
fi

# Get NextDNS config ID from config.json
nextdns_id=$(get_config '.nextdns.config_id')

# Source common nextdns setup
COMMON_SCRIPT="$MACOS_PATH/../common/config/nextdns.sh"

if [[ ! -f "$COMMON_SCRIPT" ]]; then
    log_error "Common nextdns setup script not found: $COMMON_SCRIPT"
    return 1
fi

source "$COMMON_SCRIPT"

# Run setup
setup_nextdns "$nextdns_id"

log_success "NextDNS configuration completed"
