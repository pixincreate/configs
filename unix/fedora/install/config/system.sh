#!/bin/bash
set -eEuo pipefail

# System configuration

echo "Configuring system settings"

# Set hostname
hostname=$(get_config '.system.hostname')
current_hostname=$(hostnamectl hostname)

if [[ -n "$hostname" && "$hostname" != "$current_hostname" ]]; then
    log_info "Setting hostname to: $hostname"
    if sudo hostnamectl set-hostname "$hostname"; then
        log_success "Hostname configured"
    else
        log_error "Failed to set hostname"
        return 1
    fi
else
    log_info "Hostname already set to: $current_hostname"
fi

# Configure DNF
log_info "Optimizing DNF configuration"

max_parallel=$(get_config '.dnf.max_parallel_downloads')
install_weak=$(get_config '.dnf.install_weak_deps')
fastest_mirror=$(get_config '.dnf.fastestmirror')

sudo tee /etc/dnf/dnf.conf > /dev/null <<EOF
[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=${max_parallel:-10}
install_weak_deps=${install_weak:-false}
fastestmirror=${fastest_mirror:-true}
EOF

log_success "DNF configuration optimized"

# Update system
log_info "Updating system packages"
if sudo dnf update -y --refresh; then
    log_success "System updated successfully"
else
    log_warning "System update completed with warnings"
fi

log_success "System configuration completed"
