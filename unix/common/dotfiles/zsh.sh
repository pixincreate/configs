#!/bin/bash

set -e

# Source platform detection helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/platform.sh"

setup_zsh() {
    local zsh_dir="${1:-$HOME/.zsh}"

    echo "Configuring ZSH"

    if ! command -v zsh &>/dev/null; then
        echo "[ERROR] ZSH is not installed"
        echo "[INFO] Install ZSH:"
        echo "  - macOS: brew install zsh"
        echo "  - Fedora: sudo dnf install zsh"
        echo "  - Debian: sudo apt install zsh"
        echo "  - Android: pkg install zsh"
        return 1
    fi

    mkdir -p "$zsh_dir"

    local zgenom_dir="$zsh_dir/.zgenom"

    if [[ ! -d "$zgenom_dir" ]]; then
        echo "[INFO] zgenom not found, cloning from GitHub"
        git clone https://github.com/jandamm/zgenom.git "$zgenom_dir"
        echo "[SUCCESS] zgenom installed"
    else
        echo "[INFO] zgenom already installed"
    fi

    local additionals_file="$zsh_dir/.additionals.zsh"
    local platform=$(detect_platform)

    echo "[INFO] Detected platform: $platform"
    echo "[INFO] Creating platform-specific ZSH config: $additionals_file"

    case "$platform" in
        macos)
            cat > "$additionals_file" <<'EOF'
# macOS specific ZSH configuration

# Homebrew
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Development tools
export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null)
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"

# macOS aliases
alias flush-dns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias show-hidden='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hide-hidden='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

# Homebrew completions
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi
EOF
            ;;

        fedora)
            cat > "$additionals_file" <<'EOF'
# Fedora specific ZSH configuration

# System health check
alias health-check='echo "=== System Info ===" && fastfetch && echo -e "\n=== Disk Usage ===" && df -h / /home && echo -e "\n=== Memory ===" && free -h && echo -e "\n=== Top Processes ===" && ps aux --sort=-%mem | head -n 6'

# Package management
alias dnf-update='sudo dnf upgrade --refresh'
alias dnf-clean='sudo dnf autoremove && sudo dnf clean all'
alias flatpak-update='flatpak update -y'

# Services
alias sys-failed='systemctl --failed'
alias sys-status='systemctl status'

# Development
export JAVA_HOME=/usr/lib/jvm/java-latest-openjdk
EOF
            ;;

        debian)
            cat > "$additionals_file" <<'EOF'
# Debian/Ubuntu specific ZSH configuration

# WSL detection
if grep -qi microsoft /proc/version 2>/dev/null; then
    export WSL=1
    # WSL specific aliases
    alias open='explorer.exe'
fi

# Package management
alias apt-update='sudo apt update && sudo apt upgrade -y'
alias apt-clean='sudo apt autoremove -y && sudo apt autoclean'

# Development
export JAVA_HOME=$(update-alternatives --query java | grep Value | cut -d' ' -f2 | sed 's|/bin/java||')
EOF
            ;;

        android)
            cat > "$additionals_file" <<'EOF'
# Android (Termux) specific ZSH configuration

# Termux storage
[[ ! -d ~/storage ]] && termux-setup-storage

# Termux aliases
alias backup='termux-backup'
alias restore='termux-restore'

# pkg aliases
alias pkg-update='pkg upgrade -y'
alias pkg-clean='pkg autoclean && pkg clean'

# Termux API shortcuts
alias battery='termux-battery-status'
alias location='termux-location'
alias sms='termux-sms-send'
EOF
            ;;

        *)
            cat > "$additionals_file" <<'EOF'
# Generic Unix ZSH configuration

# Add your custom configurations here
EOF
            ;;
    esac

    echo "[SUCCESS] Platform-specific ZSH config created"

    # Change default shell to ZSH
    local zsh_path=$(command -v zsh)

    if [[ "$SHELL" != "$zsh_path" ]]; then
        echo "[INFO] Current shell: $SHELL"
        echo "[INFO] ZSH path: $zsh_path"

        if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
            echo "[INFO] NON_INTERACTIVE mode: Auto-changing default shell to ZSH"
            REPLY="y"
        else
            read -p "Change default shell to ZSH? [Y/n] " -n 1 -r
            echo
        fi

        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            if [[ "$platform" == "android" ]]; then
                # Termux doesn't use chsh
                echo "[INFO] On Termux, ZSH is automatically used"
            else
                # Ensure ZSH is in /etc/shells
                if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
                    echo "[INFO] Adding ZSH to /etc/shells"
                    echo "$zsh_path" | sudo tee -a /etc/shells
                fi

                # Change shell
                if command -v chsh &>/dev/null; then
                    chsh -s "$zsh_path"
                    echo "[SUCCESS] Default shell changed to ZSH"
                    echo "[INFO] Please log out and log back in for changes to take effect"
                else
                    echo "[WARNING] chsh not available, cannot change default shell"
                fi
            fi
        else
            echo "[INFO] Keeping current shell: $SHELL"
        fi
    else
        echo "[INFO] Default shell is already ZSH"
    fi

    echo "[SUCCESS] ZSH configuration completed"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_zsh "$@"
fi
