#!/bin/bash
# Setup COPR repositories

echo "Setting up COPR repositories"

mapfile -t repos < <(get_config_array '.repositories.copr.repos')

if [[ ${#repos[@]} -eq 0 ]]; then
    log_info "No COPR repositories configured"
    return 0
fi

for repo in "${repos[@]}"; do
    if sudo dnf copr list --enabled 2>/dev/null | grep -q "$repo"; then
        log_info "COPR already enabled: $repo"
    else
        log_info "Enabling COPR: $repo"
        sudo dnf copr enable -y "$repo"
        log_success "COPR enabled: $repo"
    fi
done
