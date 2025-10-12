#!/bin/bash
# Update system firmware using fwupd

echo "Updating firmware"

if ! [[ -d /sys/firmware ]]; then
    log_info "Firmware updates skipped"
    return 0
fi

# Check if fwupd is installed
if ! cmd_exists fwupdmgr; then
    log_info "Installing fwupd"
    sudo dnf install -y fwupd || {
        log_warning "Failed to install fwupd"
        return 0
    }
fi

# Refresh firmware metadata
log_info "Refreshing firmware metadata"
if ! sudo fwupdmgr refresh --force 2>/dev/null; then
    log_warning "Failed to refresh firmware metadata"
    log_info "Continuing without firmware updates"
    return 0
fi

# Get list of devices
log_info "Checking for firmware devices"
if sudo fwupdmgr get-devices &>/dev/null; then
    log_info "Firmware devices found"
fi

# Check for available updates
if sudo fwupdmgr get-updates 2>/dev/null | grep -q "Downloading"; then
    log_info "Firmware updates available"

    if confirm "Apply firmware updates?"; then
        log_info "Applying firmware updates"
        sudo fwupdmgr update || log_warning "Failed to apply firmware updates"
        log_success "Firmware updates applied"
    else
        log_info "Skipped firmware updates"
    fi
else
    log_info "No firmware updates available"
fi

log_success "Firmware check completed"
