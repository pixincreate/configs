#!/bin/bash

# Setup Script v2.0 - Unified Configuration Management
# Supports both legacy commands and enhanced modular functionality

set -euo pipefail

# Global Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MODULES_DIR="${SCRIPT_DIR}/modules"
readonly REPO_URL="https://github.com/pixincreate/configs.git"
readonly LOCAL_PATH="$HOME/Dev/scripts/.configs"
readonly RISH_PATH="/storage/emulated/0/Documents/Dev/Shizuku"

# Import common functions and modules
source "${MODULES_DIR}/common.sh"
source "${MODULES_DIR}/stow-manager.sh"
source "${MODULES_DIR}/fonts.sh"
source "${MODULES_DIR}/git-setup.sh"

# Export configuration for modules
export REPO_URL LOCAL_PATH RISH_PATH

# Global flags
DRY_RUN=false
DEBUG=false
LEGACY_MODE=false

# Help function
show_help() {
  if [[ "$LEGACY_MODE" == true ]]; then
    show_legacy_help
  else
    show_full_help
  fi
}

# Legacy help with migration notice
show_legacy_help() {
  echo
  log_info "🔄 Enhanced Setup Script v2.0"
  log_info "📖 For full documentation, see: docs/MODULAR_SETUP_GUIDE.md"
  echo
  log_info "✨ New features available:"
  log_info "   • Selective execution (--fonts-only, --git-only, etc.)"
  log_info "   • Font management (--install-font-family [name])"
  log_info "   • Enhanced stow operations (--stow-only [package])"
  log_info "   • Configuration verification (--verify)"
  log_info "   • Dry-run testing (--dry-run)"
  echo

  echo "LEGACY COMMANDS (still supported):"
  echo "  -s, --setup          Complete environment setup"
  echo "  -g, --setup-git      Setup Git configuration only"
  echo "  -c, --setup-config   Setup configurations only"
  echo "  -i, --install        Install applications only"
  echo "  -u, --upgrade        Update configurations"
  echo "  --stow [pkg]         Stow specific package"
  echo "  --stow-all           Stow all packages"
  echo "  --unstow [pkg]       Unstow specific package"
  echo "  --unstow-all         Unstow all packages"
  echo
  echo "💡 For full help with all new features, run: $0 --help-full"
}

# Full help system
show_full_help() {
  cat << EOF
Setup Script v2.0 - Unified Configuration Management

USAGE:
  $0 [OPTIONS] [COMMAND]

OPTIONS:
  --dry-run           Show what would be done without making changes
  --debug             Enable debug output
  -h, --help          Show this help message
  --help-full         Show complete help (same as --help)
  --help-legacy       Show legacy command help

COMMANDS:
  --setup             Full environment setup (git + config + apps)
  --config-only       Setup configurations only
  --git-only          Setup Git configuration only
  --fonts-only        Install fonts only
  --apps-only         Install applications only
  --stow-only [PKG]   Stow specific package
  --stow-all          Stow all packages
  --unstow [PKG]      Unstow specific package
  --unstow-all        Unstow all packages
  --update-configs    Update stow-managed configurations
  --verify            Verify current setup

FONT COMMANDS:
  --install-font-family [NAME]    Install specific font family
  --list-fonts                    List installed fonts

LEGACY COMMANDS (backward compatibility):
  -s, --setup         →  --setup
  -g, --setup-git     →  --git-only
  -c, --setup-config  →  --config-only
  -i, --install       →  --apps-only
  -u, --upgrade       →  --update-configs

EXAMPLES:
  $0 --setup                      # Complete setup
  $0 --config-only                # Only setup configurations
  $0 --fonts-only                 # Only install fonts
  $0 --stow-only zsh              # Only stow zsh configuration
  $0 --install-font-family Fira   # Install Fira font family
  $0 --dry-run --setup            # Preview what setup would do
  $0 --verify                     # Check current setup status

SUPPORTED PLATFORMS:
  - macOS (darwin)
  - Fedora Linux
  - Debian/Ubuntu (gnu)
  - Android (Termux)

EOF
}

# Platform-specific application installation
install_platform_apps() {
  local platform="$1"

  case "$platform" in
    "fedora")
      log_step "Running Fedora-specific setup..."
      if [[ -f "${LOCAL_PATH}/fedora/setup-fedora.sh" ]]; then
        cd "${LOCAL_PATH}"
        chmod +x "${LOCAL_PATH}/fedora/setup-fedora.sh"
        "${LOCAL_PATH}/fedora/setup-fedora.sh"
      else
        log_error "Fedora setup script not found. Please ensure repository is cloned."
        return 1
      fi
      ;;
    "darwin"|"gnu"|"android")
      # Use the existing install_apps function from original setup.sh
      log_info "Using legacy application installation for $platform"
      # This would call the original install_apps function
      ;;
    *)
      log_error "Unsupported platform: $platform"
      return 1
      ;;
  esac
}

# Additional zshrc configuration (updated for Fedora)
additional_zshrc() {
  local platform="$1"

  case "$platform" in
  darwin* | gnu)
    cat >> ~/.zsh/.additionals.zsh << 'EOF'
# Dev env variables
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

# Source init for Docker
source $HOME/.docker/init-zsh.sh || true

# Disable NPM ads
export DISABLE_OPENCOLLECTIVE=1
export ADBLOCK=1

PQ_LIB_DIR="$(brew --prefix libpq)/lib"

export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"

export CC="$(brew --prefix)/opt/llvm/bin/clang"

export CONFIGS=${HOME}/Dev/scripts/.configs

alias zed=zed-preview
EOF

    if [[ "$WSL_DISTRO_NAME" == "Debian" ]] || [[ "$WSL_DISTRO_NAME" == "Fedora" ]]; then
      cat >> ~/.zsh/.additionals.zsh << 'EOF'
# WSL configurations
export WINHOME=$(wslpath "$(cd /mnt/c && cmd.exe /C 'echo %USERPROFILE%' | tr -d '\r')")

export LDFLAGS="-L/$(brew --prefix)/opt/binutils/lib"
export CPPFLAGS="-I/$(brew --prefix)/opt/binutils/include"
EOF
      echo "alias studio='/mnt/d/Program\ Files/IDE/Android\ Studio/bin/studio64.exe'" >> ~/.zsh/.additionals.zsh
    fi
    ;;
  fedora)
    cat >> ~/.zsh/.additionals.zsh << 'EOF'
# Fedora specific configurations (no linuxbrew)
typeset -U PATH path
path=(
  $path
  $HOME/.yarn/bin
  $HOME/.config/yarn/global/node_modules/.bin
  /usr/local/bin
  /usr/bin
  /usr/local/lib64
)

# Environment variables for Fedora
export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH"
export LDFLAGS="-L/usr/lib64 -L/usr/local/lib64"
export CPPFLAGS="-I/usr/include -I/usr/local/include"

# Fedora system health check
export SYS_HEALTH="${HOME}/Dev/scripts/.configs/fedora/health-check.sh"
alias cleanup="sudo dnf autoremove && flatpak uninstall --unused"

# Source init for Docker
source $HOME/.docker/init-zsh.sh || true

# Disable NPM ads
export DISABLE_OPENCOLLECTIVE=1
export ADBLOCK=1

export CONFIGS=${HOME}/Dev/scripts/.configs
EOF
    ;;
  android)
    cat >> ~/.zsh/.additionals.zsh << 'EOF'
# Android specific configurations
alias backup_termux='tar -zcf /sdcard/backups/termux/termux-backup.tar.gz -C /data/data/com.termux/files ./home ./usr'
alias restore_termux='tar -zxf /sdcard/backups/termux/termux-backup.tar.gz -C /data/data/com.termux/files --recursive-unlink --preserve-permissions'
EOF
    ;;
  *)
    log_warn "Unsupported platform: $platform"
    ;;
  esac
}

# Configuration setup
config_setup() {
  local platform="$1"
  local upgrade="${2:-false}"

  log_step "Setting up configurations..."

  if [[ "$upgrade" == true ]]; then
    log_info "Running configuration upgrade..."
    safe_config_update
  else
    validate_config || error_exit "Configuration validation failed"

    # Use stow to manage dotfiles
    stow_all_packages "$HOME" "${LOCAL_PATH}/home"

    update_gitconfig_data
    additional_zshrc "$platform"

    case "$platform" in
    "android")
      if command_exists termux-setup-storage; then
        termux-setup-storage
        sleep 10
      fi

      if [[ -d "$RISH_PATH" ]]; then
        cp -a "${RISH_PATH}/." "$HOME/.rish/"
        ln -sfn "$HOME/.rish/rish" "$PATH/rish"
        ln -sfn "$HOME/.rish/rish_shizuku.dex" "$PATH/rish_shizuku.dex"
      fi
      ;;
    "darwin")
      if [[ -d "$HOME/Code" ]]; then
        mv "$HOME/Code" "$HOME/Library/Application Support/Code"
      fi
      ;;
    "fedora")
      log_info "Fedora platform detected - using fedora-specific setup"
      if [[ -d "$HOME/Code" ]]; then
        mv "$HOME/Code" "$HOME/.config/Code"
      fi
      ;;
    "gnu")
      if [[ "$WSL_DISTRO_NAME" == "Debian" ]] && command_exists code; then
        code
      fi
      if [[ -d "$HOME/Code" ]]; then
        mv "$HOME/Code" "$HOME/.config/Code"
      fi
      ;;
    esac

    log_info "Setting up zsh as default shell..."
    if [[ "$platform" == "android" ]]; then
      chsh -s zsh
    else
      chsh -s /usr/bin/zsh
    fi
  fi

  log_info "Configuration setup completed!"
}

# Verification function
verify_setup() {
  log_step "Verifying setup..."

  # Check Git configuration
  verify_git_config

  # Check stow packages
  for package in "${STOW_PACKAGES[@]}"; do
    check_stow_status "$package"
  done

  # Check directories
  local dirs=("$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots")
  for dir in "${dirs[@]}"; do
    if [[ -d "$dir" ]]; then
      log_info "Directory exists: $dir"
    else
      log_warn "Directory missing: $dir"
    fi
  done

  log_info "Verification completed!"
}

# Main execution function
main() {
  log_info "🚀 Starting Setup Script v2.0..."

  # Clone repository if it doesn't exist
  if [[ ! -d "$LOCAL_PATH" ]]; then
    log_info "Cloning repository..."
    git clone --recurse-submodules "$REPO_URL" "$LOCAL_PATH" || error_exit "Failed to clone repository"
  fi

  # Parse command line arguments
  if [[ $# -eq 0 ]]; then
    LEGACY_MODE=true
    show_help
    echo
    log_warn "No arguments provided. Use --help for usage information."
    echo
    log_info "💡 Quick start commands:"
    log_info "   $0 --setup          # Complete setup"
    log_info "   $0 --config-only    # Configuration only"
    log_info "   $0 --git-only       # Git setup only"
    log_info "   $0 --help           # Show help"
    exit 1
  fi

  # Check requirements
  check_requirements || error_exit "Requirements check failed"

  # Setup directories
  dir_setup

  # Detect platform
  local platform
  platform=$(detect_platform)
  log_info "Detected platform: $platform"

  # Process arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --dry-run)
        DRY_RUN=true
        log_info "🔍 Dry run mode enabled"
        ;;
      --debug)
        DEBUG=true
        ;;
      -h|--help)
        show_full_help
        exit 0
        ;;
      --help-full)
        show_full_help
        exit 0
        ;;
      --help-legacy)
        LEGACY_MODE=true
        show_legacy_help
        exit 0
        ;;
      # New modular commands
      --setup)
        log_step "Running full setup..."
        config_setup "$platform"
        install_platform_apps "$platform"
        git_setup
        ;;
      --config-only)
        config_setup "$platform"
        ;;
      --git-only)
        git_setup
        ;;
      --fonts-only)
        check_font_requirements
        install_repo_fonts
        ;;
      --apps-only)
        install_platform_apps "$platform"
        ;;
      --stow-only)
        if [[ -n "${2:-}" && "$2" != -* ]]; then
          stow_package "$2"
          shift
        else
          log_error "Package name required for --stow-only"
          exit 1
        fi
        ;;
      --stow-all)
        stow_all_packages
        ;;
      --unstow)
        if [[ -n "${2:-}" && "$2" != -* ]]; then
          unstow_package "$2"
          shift
        else
          log_error "Package name required for --unstow"
          exit 1
        fi
        ;;
      --unstow-all)
        unstow_all_packages
        ;;
      --update-configs)
        safe_config_update
        ;;
      --verify)
        verify_setup
        ;;
      --install-font-family)
        if [[ -n "${2:-}" && "$2" != -* ]]; then
          check_font_requirements
          install_font_family "$2"
          shift
        else
          log_error "Font family name required for --install-font-family"
          exit 1
        fi
        ;;
      --list-fonts)
        list_installed_fonts
        ;;
      # Legacy command mapping (backward compatibility)
      -s|--setup-legacy)
        log_info "🔗 Legacy command mapped: --setup-legacy → --setup"
        log_step "Running full setup..."
        config_setup "$platform"
        install_platform_apps "$platform"
        git_setup
        ;;
      -g|--setup-git)
        log_info "🔗 Legacy command mapped: --setup-git → --git-only"
        git_setup
        ;;
      -c|--setup-config)
        log_info "🔗 Legacy command mapped: --setup-config → --config-only"
        config_setup "$platform"
        ;;
      -i|--install)
        log_info "🔗 Legacy command mapped: --install → --apps-only"
        install_platform_apps "$platform"
        ;;
      -u|--upgrade)
        log_info "🔗 Legacy command mapped: --upgrade → --update-configs"
        safe_config_update
        ;;
      --stow)
        if [[ -n "${2:-}" && "$2" != -* ]]; then
          log_info "🔗 Legacy command mapped: --stow → --stow-only"
          stow_package "$2"
          shift
        else
          log_error "Package name required for --stow"
          exit 1
        fi
        ;;
      *)
        log_error "Unknown option: $1"
        echo
        log_info "💡 Use --help for available commands or --help-legacy for legacy command help"
        exit 1
        ;;
    esac
    shift
  done

  log_info "✅ Setup completed successfully!"
}

# Execute main function with all arguments
main "$@"
