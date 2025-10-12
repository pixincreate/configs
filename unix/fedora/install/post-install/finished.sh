#!/bin/bash
# Completion message and reboot prompt

echo "Installation completed successfully"

log_header "Fedora Setup Completed"

echo "Summary:"
echo "  - Repositories configured (RPM Fusion, COPR, Terra)"
echo "  - Packages installed (DNF, Flatpak, Rust tools)"
echo "  - System optimizations applied"
echo "  - Hardware drivers configured"
echo "  - Dotfiles deployed"
echo ""

# Check if reboot is needed
needs_reboot=false

# Check for NVIDIA installation
if lspci | grep -i nvidia &>/dev/null && pkg_installed akmod-nvidia-open || pkg_installed akmod-nvidia; then
    log_warning "NVIDIA drivers installed - reboot required"
    needs_reboot=true
fi

# Check for kernel updates
current_kernel=$(uname -r)
latest_kernel=$(rpm -q kernel --last | head -1 | awk '{print $1}' | sed 's/kernel-//')

if [[ "$current_kernel" != "$latest_kernel" ]]; then
    log_warning "Kernel updated - reboot required"
    needs_reboot=true
fi

# Check if default shell was changed
zsh_path=$(command -v zsh)
current_shell=$(getent passwd "$USER" | cut -d: -f7)

if [[ "$current_shell" != "$zsh_path" ]] && grep -q "zsh" /etc/shells; then
    log_warning "Default shell changed - logout required"
fi

# Check if user was added to docker group
if groups "$USER" | grep -q docker && ! id -nG | grep -q docker; then
    log_warning "Docker group membership changed - logout required"
fi

echo ""

if [[ "$needs_reboot" == "true" ]]; then
    log_warning "System reboot is required for all changes to take effect"
    echo ""

    if confirm "Reboot now?" "Y"; then
        log_info "Rebooting system in 5 seconds..."
        sleep 5
        sudo systemctl reboot
    else
        log_info "Please reboot manually when ready"
    fi
else
    log_success "No reboot required"
    log_info "Please log out and back in for shell and group changes to take effect"
fi

echo ""
log_success "Thank you for using Fedora Declarative Setup"
