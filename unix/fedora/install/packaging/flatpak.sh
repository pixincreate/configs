#!/bin/bash
# Install Flatpak applications

echo "Installing Flatpak applications"

# Ensure Flatpak is installed
if ! cmd_exists flatpak; then
    log_info "Installing Flatpak"
    sudo dnf install -y flatpak
fi

# Add Flathub repository
if ! flatpak remote-list 2>/dev/null | grep -q flathub; then
    log_info "Adding Flathub repository"
    if flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        log_success "Flathub repository added"
    else
        log_error "Failed to add Flathub repository"
        return 1
    fi
fi

# Read Flatpak apps from package file
pkg_file="$OMAFORGE_PATH/packages/flatpak.packages"

if [[ ! -f "$pkg_file" ]]; then
    log_info "No Flatpak applications configured"
    return 0
fi

mapfile -t apps < <(grep -v '^#' "$pkg_file" | grep -v '^$')

if [[ ${#apps[@]} -eq 0 ]]; then
    log_info "No Flatpak applications configured"
    return 0
fi

log_info "Installing ${#apps[@]} Flatpak applications"

for app in "${apps[@]}"; do
    if flatpak list | grep -q "$app"; then
        log_info "Already installed: $app"
    else
        log_info "Installing: $app"
        flatpak install -y flathub "$app"
    fi
done

log_success "Flatpak applications installed"
