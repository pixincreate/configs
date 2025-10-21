#!/bin/bash

set -e

# Source platform detection helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/platform.sh"

setup_zsh() {
    local zsh_dir="${1:-$HOME/.zsh}"

    echo "Configuring ZSH"

    local additionals_file="$zsh_dir/.additionals.zsh"
    local platform=$(detect_platform)

    echo "[INFO] Detected platform: $platform"

    if [[ -f "$additionals_file" ]]; then
        local backup_file="${additionals_file}.bak"
        cp "$additionals_file" "$backup_file"
        echo "[INFO] Backed up existing config to: $backup_file"
    fi

    echo "[INFO] Creating platform-specific ZSH config: $additionals_file"

    case "$platform" in
        macos)
            cat > "$additionals_file" <<'EOF'
# macOS specific configurations
typeset -U PATH path
path=(
    $path
    $HOME/.yarn/bin
    $HOME/.config/yarn/global/node_modules/.bin
    $(brew --prefix)/opt/coreutils/libexec/gnubin
    $(brew --prefix)/opt/findutils/libexec/gnubin
    $(brew --prefix)/opt/gnu-getopt/bin
    $(brew --prefix)/opt/gnu-indent/libexec/gnubin
    $(brew --prefix)/opt/gnu-tar/libexec/gnubin
    $(brew --prefix)/opt/binutils/bin
    $(brew --prefix)/opt/homebrew/opt/openjdk@21/bin
    $(brew --prefix)/opt/homebrew/opt/openjdk@17/bin
    $(brew --prefix)/opt/llvm/bin
)

# Disable NPM ads
export DISABLE_OPENCOLLECTIVE=1
export ADBLOCK=1

PQ_LIB_DIR="$(brew --prefix libpq)/lib"

export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CC="$(brew --prefix)/opt/llvm/bin/clang"

# omaforge bin
export PATH="$HOME/Dev/.configs/unix/macos/bin:$PATH"

# macOS aliases
alias flush-dns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias show-hidden='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hide-hidden='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

alias zed=zed-preview
EOF
            ;;

        fedora)
            cat > "$additionals_file" <<'EOF'
# omaforge bin
export PATH="$HOME/Dev/.configs/unix/fedora/bin:$PATH"
# Fedora specific configurations
export SYS_HEALTH="${HOME}/Dev/.configs/unix/fedora/health-check.sh"
alias cleanup="sudo dnf autoremove && flatpak uninstall --unused"
alias dnf-clean='sudo dnf autoremove && sudo dnf clean all'
alias secure_boot_retrigger='sudo kmodgenca -a && sudo mokutil --import /etc/pki/akmods/certs/public_key.der'

export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT=wayland
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland
EOF
            ;;

        debian)
            cat > "$additionals_file" <<'EOF'
# Debian specific configurations
export LDFLAGS="-L/$(brew --prefix)/opt/binutils/lib"
export CPPFLAGS="-I/$(brew --prefix)/opt/binutils/include"

# WSL configurations (if applicable)
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    export WINHOME=$(wslpath "$(cd /mnt/c && cmd.exe /C 'echo %USERPROFILE%' | tr -d '\\r')")
    alias studio='/mnt/d/Program\\ Files/IDE/Android\\ Studio/bin/studio64.exe'
fi
EOF
            ;;

        android)
            cat > "$additionals_file" <<'EOF'
# Termux storage
[[ ! -d ~/storage ]] && termux-setup-storage
# pkg aliases
alias pkg-update='pkg upgrade -y'
alias pkg-clean='pkg autoclean && pkg clean'

# Android/Termux specific configurations
alias backup_termux='tar -zcf /sdcard/backups/termux/termux-backup.tar.gz -C /data/data/com.termux/files ./home ./usr'
alias restore_termux='tar -zxf /sdcard/backups/termux/termux-backup.tar.gz -C /data/data/com.termux/files --recursive-unlink --preserve-permissions'
alias CONFIGS="${HOME}/Dev/.configs"
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

        read -p "Change default shell to ZSH? [Y/n] " -n 1 -r
        echo

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
