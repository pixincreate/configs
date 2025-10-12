#!/bin/bash
# System configuration for macOS

echo "Configuring system settings"

# Get hostname from config
hostname=$(get_config '.system.hostname')

if [[ -n "$hostname" ]]; then
    current_hostname=$(scutil --get ComputerName)

    if [[ "$current_hostname" != "$hostname" ]]; then
        log_info "Setting hostname to: $hostname"

        # Set all hostname types on macOS
        sudo scutil --set ComputerName "$hostname"
        sudo scutil --set LocalHostName "$hostname"
        sudo scutil --set HostName "$hostname"

        log_success "Hostname set to: $hostname"
    else
        log_info "Hostname already set to: $hostname"
    fi
else
    log_info "No hostname configured, skipping"
fi

log_success "System configuration completed"
