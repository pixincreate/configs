#!/bin/bash
# System configuration

echo "Configuring system settings"

# Set hostname
hostname=$(get_config '.system.hostname')
current_hostname=$(hostnamectl hostname)

if [[ -n "$hostname" && "$hostname" != "$current_hostname" ]]; then
    log_info "Setting hostname to: $hostname"
    sudo hostnamectl set-hostname "$hostname"
    log_success "Hostname configured"
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
sudo dnf update -y --refresh

log_success "System configuration completed"
