#!/bin/bash
# Homebrew installation and setup for macOS

echo "Setting up Homebrew"

# Check if Homebrew is already installed
if command -v brew &>/dev/null; then
    log_info "Homebrew already installed"
    brew update
    log_success "Homebrew updated"
    return 0
fi

log_info "Installing Homebrew"

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH
if [[ -f /opt/homebrew/bin/brew ]]; then
    # Apple Silicon
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    # Intel Mac
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Disable analytics
brew analytics off

log_success "Homebrew installation completed"
