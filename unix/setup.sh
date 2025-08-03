#!/bin/bash

# DECLARATIONS
# These values can be overrided by exporting them in the shell as environment variables

readonly REPO_URL="https://github.com/pixincreate/configs.git"

readonly LOCAL_PATH="$HOME/Dev/scripts/.configs"
readonly RISH_PATH="/storage/emulated/0/Documents/Dev/Shizuku"

readonly GITCONFIG_EMAIL="69745008+pixincreate@users.noreply.github.com"
readonly GITCONFIG_USERNAME="PiX"
readonly GITCONFIG_SIGNGING_KEY="$HOME/.ssh/id_ed25519_sign.pub"

readonly DEFAULT_SSH_PERMS=0600
readonly SUPPORTED_PLATFORMS=("darwin" "gnu" "android" "fedora")
readonly STOW_PACKAGES=("config" "git" "ssh" "vscode" "zsh")

# Helper functions
print() {
  local data="$1"
  local cr_flag="$2"

  if [[ "$cr_flag" == true ]]; then
    echo -ne "${data}\r"
  else
    echo -e "${data}"
  fi
}

git_checkup() {
  case "$OSTYPE" in
  linux-gnu)
    # Check if running in WSL, if yes, copy the keys
    if [[ "$WSL_DISTRO_NAME" == "Debian" ]]; then
      print "Setting up git for WSL..." true
      WINHOME=$(wslpath "$(cd /mnt/c && cmd.exe /C 'echo %USERPROFILE%' | tr -d '\r')")

      files="id_ed25519_auth id_ed25519_auth.pub id_ed25519_sign id_ed25519_sign.pub"
      for file in $files; do
        src="$WINHOME/.ssh/$file"
        dest="$HOME/.ssh/$file"

        if [ -f "$src" ]; then
          cp "$src" "$dest"
        else
          print "File not found: $src"
        fi
      done
      chmod $DEFAULT_SSH_PERMS .ssh/*

      print "WSL setup completed!"
    fi
    ;;
  linux-android)
    print "Setting up git for Android..." true
    cp -a /storage/emulated/0/Documents/Dev/.ssh/. $HOME/.ssh/
    chmod $DEFAULT_SSH_PERMS .ssh/*
    print "Android setup completed!"
    ;;
  *)
    print "unsupported platform: $OSTYPE"
    ;;
  esac
}

update_gitconfig_data() {
  git_checkup

  sed -i.bak "s/email = example@email.com/email = ${GITCONFIG_EMAIL}/" ~/.gitconfig
  sed -i.bak "s/name = username/name = ${GITCONFIG_USERNAME}/" ~/.gitconfig
  sed -i.bak "s|signingkey = ~/.ssh/signingkey|signingkey = ${GITCONFIG_SIGNGING_KEY}|" ~/.gitconfig
}

# Function to generate SSH keys (DRY principle)
generate_ssh_keys() {
  local email="$1"
  local auth_path="$HOME/.ssh/id_ed25519_auth"
  local sign_path="$HOME/.ssh/id_ed25519_sign"

  print "Path to authentication file: ${auth_path}"
  print "Path to signature file: ${sign_path}"

  ssh-keygen -t ed25519 -C "$email" -f "$auth_path"
  eval "$(ssh-agent -s)"
  ssh-keygen -t ed25519 -C "$email" -f "$sign_path"
  eval "$(ssh-agent -s)"

  ssh-add "$auth_path"
  ssh-add "$sign_path"
}

# Function to copy keys and prompt (DRY principle)
copy_and_update_keys() {
  local auth_path="$HOME/.ssh/id_ed25519_auth"
  local sign_path="$HOME/.ssh/id_ed25519_sign"

  print "You have 3 minutes each to visit https://github.com/settings/keys and update keys on GitHub." true
  sleep 4
  pbcopy <"$auth_path"
  print "Update the Authentication key" true
  sleep 180
  pbcopy <"$sign_path"
  echo "Update the Signature key" true
  sleep 180

  # It is user's responsibility to update fingerprints on GitHub
  ssh -T git@github.com
}

install_brew() {
  print "Installing Homebrew..." true

  # Check if Homebrew is installed
  if ! command -v brew &>/dev/null; then
    yes '' | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH
    print "Adding Homebrew to PATH..." true
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
      (
        echo
        echo -e 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
      ) >>~/.bashrc
      (
        echo
        echo -e 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
      ) >>~/.zsh/.zprofile
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

      # Install the necessities for brew
      sudo apt-get install -y build-essential

    elif [[ "$OSTYPE" == "darwin" ]]; then
      (
        echo
        echo -e 'eval "$(/opt/homebrew/bin/brew shellenv)"'
      ) >>~/.zsh/.zprofile
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

  else
    print "Homebrew is already installed. Trying to upgrade..." true
    brew update
  fi

  # Turn brew analytics off
  brew analytics off

  print "Homebrew installation completed!"
}

additional_zshrc() {
  local platform="$1"

  case "$platform" in
  darwin* | gnu | fedora)
    echo '
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

      # Added by OrbStack: command-line tools and integration
      # Comment this line if you do not want it to be added again.
      # source ~/.orbstack/shell/init.zsh 2>/dev/null || :

      # Disable NPM ads
      export DISABLE_OPENCOLLECTIVE=1
      export ADBLOCK=1

      PQ_LIB_DIR="$(brew --prefix libpq)/lib"

      export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
      export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"

      export CC="$(brew --prefix)/opt/llvm/bin/clang"

      export CONFIGS=${HOME}/Dev/scripts/.configs

      alias zed=zed-preview
    ' >>~/.zsh/.additionals.zsh

    if [[ "$WSL_DISTRO_NAME" == "Debian" ]] || [[ "$WSL_DISTRO_NAME" == "Fedora" ]]; then
      echo '
        # WSL configurations
        export WINHOME=$(wslpath "$(cd /mnt/c && cmd.exe /C '\''echo %USERPROFILE%'\'' | tr -d '\''\r'\'')")

        export LDFLAGS="-L/$(brew --prefix)/opt/binutils/lib"
        export CPPFLAGS="-I/$(brew --prefix)/opt/binutils/include"
        ' >>~/.zsh/.additionals.zsh
      echo "alias studio='/mnt/d/Program\ Files/IDE/Android\ Studio/bin/studio64.exe'" >>~/.zsh/.additionals.zsh
    fi

    if [[ "$platform" == "fedora" ]]; then
      echo '
        # Fedora specific configurations
        export SYS_HEALTH="$HOME/Dev/scripts/fedora/health-check.sh"
        alias cleanup='sudo dnf autoremove && flatpak uninstall --unused'

      ' >>~/.zsh/.additionals.zsh
    fi
    ;;
  android)
    (
      echo
      echo -e "alias backup_termux='tar -zcf /sdcard/backups/termux/termux-backup.tar.gz -C /data/data/com.termux/files ./home ./usr'"
      echo -e "alias restore_termux='tar -zxf /sdcard/backups/termux/termux-backup.tar.gz -C /data/data/com.termux/files --recursive-unlink --preserve-permissions'"
    ) >>~/.zsh/.additionals.zsh
    ;;
  *)
    print "Unsupported platform: $platform"
    ;;
  esac
}

# Logging Functions
log_error() { echo "[ERROR] $*" >&2; }
log_info() { echo "[INFO] $*"; }
log_debug() { [[ $DEBUG ]] && echo "[DEBUG] $*"; }

check_requirements() {
  local -a required_cmds=("curl" "git" "ssh-keygen" "wget" "zsh")
  for cmd in "${required_cmds[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || {
      log_error "Required command not found: $cmd"
      return 1
    }
  done

  # Check for stow and install if not present
  if ! command -v stow &>/dev/null; then
    log_info "GNU Stow not found. Installing..."
    case "$OSTYPE" in
      darwin*)
        brew install stow
        ;;
      linux-gnu*)
        if command -v apt-get &>/dev/null; then
          sudo apt-get update && sudo apt-get install -y stow
        elif command -v dnf &>/dev/null; then
          sudo dnf install -y stow
        elif command -v pacman &>/dev/null; then
          sudo pacman -S --noconfirm stow
        else
          log_error "Could not install stow. Please install it manually."
          return 1
        fi
        ;;
      linux-android)
        pkg install stow
        ;;
      *)
        log_error "Unsupported platform for stow installation: $OSTYPE"
        return 1
        ;;
    esac
  fi
}

help() {
  print "Usage: setup.sh [options]"
  print "Options:"
  print "  --upgrade              Upgrade configurations"
  print "  --setup                Setup the environment"
  print "  --git-setup            Setup Git configuration"
  print "  --config-setup         Setup configurations"
  print "  --install              Install applications"
  print "  --stow [PACKAGE]       Stow specific package (${STOW_PACKAGES[*]})"
  print "  --stow-all             Stow all packages"
  print "  --unstow [PACKAGE]     Unstow specific package"
  print "  --unstow-all           Unstow all packages"
  print "  --help                 Display this help message"
  print "Example:"
  print "- Initial setup:"
  print "  \`setup.sh --setup\`"
  print "- Upgrade configs:"
  print "  \`setup.sh --upgrade --config-setup\`"
  print "- Stow only zsh config:"
  print "  \`setup.sh --stow zsh\`"
  exit 0
}

dir_setup() {
  print "Setting up directories..." true

  # Create the necessary directories
  mkdir -p \
    "${HOME}/.config" \
    "${HOME}/.rish" \
    "${HOME}/.ssh" \
    "${HOME}/.zsh" \
    "${HOME}/.zsh/.zgenom"

  print "Directories setup completed!"
}

change_shopt() {
  local flag="$1"

  if [[ "$flag" == true ]]; then
    # Allow dotglob to include dot files and folders
    shopt -s dotglob
    # Allow loops over empty directory
    shopt -s nullglob
  else
    # Deny dotglob to include dot files and folders
    shopt -u dotglob
    # Deny loops over empty directory
    shopt -u nullglob
  fi
}

validate_config() {
  [[ -z "$REPO_URL" ]] && return 1
  [[ -z "$LOCAL_PATH" ]] && return 1
  return 0
}

git_setup() {
  print "Fresh setup Git or restore existing configuration?"
  select confirm in "Fresh setup" "Restore existing" "exit"; do
    case $confirm in
    "Fresh setup")
      # Fresh setup (if selected)
      print "Performing fresh Git setup..." true

      # Prompt for user details (single loop)
      while [[ -z "$user_name" || -z "$user_email" || -z "$private_email" ]]; do

        read -p "Enter your user name for configuring git: " user_name
        # Validate non-empty and non-whitespace
        if [[ -z "$user_name" || "$user_name" =~ ^[[:space:]]*$ ]]; then
          print "Username cannot be empty or whitespace." true
        fi

        read -p "Enter your email for configuring git: " user_email
        # Validate non-empty and non-whitespace
        if [[ -z "$user_email" || "$user_email" =~ ^[[:space:]]*$ ]]; then
          print "Email cannot be empty or whitespace." true
        fi

        read -p "Enter your no-reply email for configuring git: " private_email
        # Validate non-empty and non-whitespace
        if [[ -z "$private_email" || "$private_email" =~ ^[[:space:]]*$ ]]; then
          print "No-reply email cannot be empty or whitespace." true
        fi
      done

      GITCONFIG_USERNAME="$user_name"
      GITCONFIG_EMAIL="$private_email"

      update_gitconfig_data
      generate_ssh_keys "$user_email"
      copy_and_update_keys
      break
      ;;
    "Restore existing")
      # Restore existing configuration
      print "Restoring existing Git configuration..." true
      update_gitconfig_data
      print "Existing Git configuration restored!"
      break
      ;;
    "exit")
      break
      ;;
    *)
      print "Invalid selection. Please choose '1' for fresh setup or '2' to restore existing git configuration."
      ;;
    esac
  done
}

install_apps() {
  print "Installing applications..." true

  local platform="$1"

  [[ -z "$platform" ]] && {
    print "Platform parameter required.\nSupported platforms: ${SUPPORTED_PLATFORMS[*]}"
    return 1
  }

  if [[ "$platform" != "android" ]]; then
    install_brew
  fi

  # List of applications to install
  android_specific=("termux-api" "termux-tools" "tsu")
  applications=(
    "alacritty" "alt-tab" "android-studio" "bitwarden" "brave-browser@beta"
    "firefox@dev" "zen" "localsend" "maccy" "obsidian" "rectangle" "signal@beta"
    "visual-studio-code"
  )
  dev_applications=("docker" "kubectl" "nextdns/tap/nextdns" "node")
  languages=("gcc" "python" "rustup" "sqlite")
  terminal_additions=(
    "bat" "binutils" "coreutils" "croc" "direnv" "eza" "fastfetch" "fzf" "git-delta"
    "jq" "lazygit" "micro" "multitail" "neovim" "pipx" "ripgrep"  "stow" "tar" "tmux"
    "topgrade" "tree" "xclip" "zoxide"
  )
  tools=(
    "android-platform-tools" "android-tools" "openssh"
  )

  # Install applications based on the platform
  case "$platform" in
  darwin)
    apps_category=(
      "${applications[@]}" "${dev_applications[@]}" "${languages[@]}"
      "${terminal_additions[@]}" "${tools[@]}"
    )
    for app in "${apps_category[@]}"; do
      exclude_list=("android-tools")
      [[ " ${exclude_list[*]} " =~ " ${app} " ]] && echo "Skipping unsupported application: $app" && continue
      if command -v "${app}" &>/dev/null; then
        echo "$app is already installed. Trying to upgrade..."
        brew upgrade "$app"
      else
        echo "Installing $app..."
        brew install "$app"
      fi
    done
    ;;
  fedora)
    print "Running Fedora-specific setup..." true
    if [[ -f "${LOCAL_PATH}/fedora/setup-fedora.sh" ]]; then
      cd "${LOCAL_PATH}"
      chmod +x "${LOCAL_PATH}/fedora/setup-fedora.sh"
      "${LOCAL_PATH}/fedora/setup-fedora.sh"
    else
      print "Fedora setup script not found. Please ensure the repository is properly cloned."
      return 1
    fi
    ;;
  gnu)
    apps_category=(
      "${dev_applications[@]}" "${languages[@]}"
      "${terminal_additions[@]}"
    )
    echo "Assuming you are using APT package manager..."
    echo "Updating package list..."
    sudo apt-get update -y

    for app in "${apps_category[@]}"; do
      exclude_list=("android-tools")
      [[ " ${exclude_list[*]} " =~ " ${app} " ]] && echo "Skipping unsupported application: $app" && continue
      if command -v "${app}" &>/dev/null; then
        echo "$app is already installed. Trying to upgrade..."
        sudo apt-get upgrade "$app"
      else
        echo "Installing $app..."
        sudo apt-get install "$app" -y
      fi
    done
    ;;
  android)
    apps_category=(
      "${android_specific[@]}"
      "${languages[@]}" "${terminal_additions[@]}"
    )
    for app in "${apps_category[@]}"; do
      exclude_list=("android-platform-tools" "gcc" "xclip")
      [[ " ${exclude_list[*]} " =~ " ${app} " ]] && echo "Skipping unsupported application: $app" && continue
      if command -v "${app}" &>/dev/null; then
        echo "$app is already installed. Trying to upgrade..."
        pkg upgrade "$app" || echo "Failed to upgrade $app"
      else
        echo "Installing $app..."
        pkg install "$app" || echo "Failed to install $app"
      fi
    done
    ;;
  *)
    print "Unsupported platform: $platform\nSupported platforms: ${SUPPORTED_PLATFORMS[*]}"
    ;;
  esac

  print "Installing trash-cli..." true
  pipx ensurepath
  pipx install "trash-cli"

  # Setup crontab to auto empty trash after 60 days
  (
    crontab -l
    echo "@daily $(which trash-empty) 60"
  ) | crontab -
  # List it for satisfaction
  crontab -l

  print "Application installation completed!"
  return $? # Return the exit status of the last command
}

# Function to handle stowing packages
stow_package() {
  local package="$1"
  local target="${2:-$HOME}"
  local stow_dir="${3:-${LOCAL_PATH}/home}"

  if [ ! -d "$stow_dir/$package" ]; then
    log_error "Package directory not found: $stow_dir/$package"
    return 1
  fi

  log_info "Stowing $package to $target..."

  # Use --no-folding to ensure stow doesn't try to fold directories
  # Use --restow to handle any existing links
  stow --no-folding --restow --dir="$stow_dir" --target="$target" "$package"

  if [ $? -eq 0 ]; then
    log_info "Successfully stowed $package"
  else
    log_error "Failed to stow $package"
    return 1
  fi
}

# Function to handle unstowing packages
unstow_package() {
  local package="$1"
  local target="${2:-$HOME}"
  local stow_dir="${3:-${LOCAL_PATH}/home}"

  if [ ! -d "$stow_dir/$package" ]; then
    log_error "Package directory not found: $stow_dir/$package"
    return 1
  fi

  log_info "Unstowing $package from $target..."

  stow --delete --dir="$stow_dir" --target="$target" "$package"

  if [ $? -eq 0 ]; then
    log_info "Successfully unstowed $package"
  else
    log_error "Failed to unstow $package"
    return 1
  fi
}

# Function to handle stowing all packages
stow_all_packages() {
  local target="${1:-$HOME}"
  local stow_dir="${2:-${LOCAL_PATH}/home}"

  log_info "Stowing all packages to $target..."

  for package in "${STOW_PACKAGES[@]}"; do
    stow_package "$package" "$target" "$stow_dir"
  done
}

# Function to handle unstowing all packages
unstow_all_packages() {
  local target="${1:-$HOME}"
  local stow_dir="${2:-${LOCAL_PATH}/home}"

  log_info "Unstowing all packages from $target..."

  for package in "${STOW_PACKAGES[@]}"; do
    unstow_package "$package" "$target" "$stow_dir"
  done
}

config_setup() {
  print "Setting up configurations..." true

  local platform="$1"

  if [[ "$upgrade" == true ]]; then
    print "Running upgrade..." true
    if git diff-index --quiet HEAD --; then
      print "Configs are unmodified, pulling latest changes from main..." true
      git -C "${LOCAL_PATH}" pull

      git -C "${LOCAL_PATH}" submodule update --init --recursive

      # Use stow to manage dotfiles
      stow_all_packages "$HOME" "${LOCAL_PATH}/home"

      if [[ -d "${XDG_CONFIG_HOME}/tmux" ]]; then
        tmux source ${XDG_CONFIG_HOME}/tmux/tmux.conf
      fi

      update_gitconfig_data
      additional_zshrc $platform
    else
      print "Configs have been modified. Please \`commit\` or \`stash\` your changes first."
      exit 1
    fi
  else
    # Clone the repository if it does not exist
    if [ ! -d "${LOCAL_PATH}" ]; then
      git clone --recurse-submodules "${REPO_URL}" "${LOCAL_PATH}" || {
        print "Failed to clone repository"
        exit 1
      }
    fi

    validate_config

    # Use stow to manage dotfiles
    stow_all_packages "$HOME" "${LOCAL_PATH}/home"

    update_gitconfig_data
    additional_zshrc $platform

    case "$platform" in
    "android")
      termux-setup-storage
      sleep 10

      cp -a ${RISH_PATH}/. $HOME/.rish/
      ln -sfn $HOME/.rish/rish $PATH/rish
      ln -sfn $HOME/.rish/rish_shizuku.dex $PATH/rish_shizuku.dex
      ;;
    "darwin")
      if [ -d "$HOME/Code" ]; then
        mv "$HOME/Code" "$HOME/Library/Application Support/Code"
      fi
      ;;
    "fedora")
      print "Fedora platform detected - using fedora-specific setup" true
      if [ -d "$HOME/Code" ]; then
        mv "$HOME/Code" "$HOME/.config/Code"
      fi
      ;;
    "gnu")
      if [[ "$WSL_DISTRO_NAME" == "Debian" ]]; then
        command -v code &>/dev/null && code
      fi
      if [ -d "$HOME/Code" ]; then
        mv "$HOME/Code" "$HOME/.config/Code"
      fi
      ;;
    *)
      print "Unsupported platform: $platform\nSupported platforms: ${SUPPORTED_PLATFORMS[*]}"
      ;;
    esac

    print "Setting up zshell..." true
    if [[ "$platform" == "android" ]]; then
      chsh -s zsh
    else
      chsh -s "$(which zsh) $(whoami)"
    fi
  fi
  print "Configurations setup completed!"
}

main() {
  print "Running setup script..." true

  change_shopt true

  # Parse command line arguments
  if [[ "$#" -eq 0 ]]; then
    print "No arguments passed. Exiting..." true
    sleep 2
    print "Run setup.sh --help for more information."
    exit 1
  fi

  check_requirements

  local stow_pkg=""
  local unstow_pkg=""

  while [[ "$#" -gt 0 ]]; do
    case $1 in
    -s | --setup) setup=true ;;
    -g | --setup-git) git_setup=true ;;
    -c | --setup-config) config_setup=true ;;
    -i | --install) install=true ;;
    -u | --upgrade) upgrade=true ;;
    --stow)
      if [[ -n "$2" && "$2" != -* ]]; then
        stow_pkg="$2"
        shift
      else
        log_error "No package specified for stowing"
        exit 1
      fi
      ;;
    --stow-all) stow_all=true ;;
    --unstow)
      if [[ -n "$2" && "$2" != -* ]]; then
        unstow_pkg="$2"
        shift
      else
        log_error "No package specified for unstowing"
        exit 1
      fi
      ;;
    --unstow-all) unstow_all=true ;;
    -h | --help)
      help
      ;;
    *)
      echo "Unknown parameter passed: $1"
      exit 1
      ;;
    esac
    shift
  done

  dir_setup

  # Determine platform
  case "$OSTYPE" in
  darwin*)
    setup_platform="darwin"
    ;;
  linux-gnu)
    # Check if it's Fedora
    if [[ -f /etc/fedora-release ]]; then
      setup_platform="fedora"
    else
      setup_platform="gnu"
    fi
    ;;
  linux-android)
    setup_platform="android"
    ;;
  *)
    echo "unsupported platform: $OSTYPE\nSupported platforms: ${SUPPORTED_PLATFORMS[*]}"
    ;;
  esac

  # Handle stow/unstow requests
  if [[ -n "$stow_pkg" ]]; then
    stow_package "$stow_pkg" "$HOME" "${LOCAL_PATH}/home"
  fi

  if [[ -n "$unstow_pkg" ]]; then
    unstow_package "$unstow_pkg" "$HOME" "${LOCAL_PATH}/home"
  fi

  if [[ "$stow_all" == true ]]; then
    stow_all_packages "$HOME" "${LOCAL_PATH}/home"
  fi

  if [[ "$unstow_all" == true ]]; then
    unstow_all_packages "$HOME" "${LOCAL_PATH}/home"
  fi

  # Conditional execution based on flags
  if [[ "$setup" == true ]]; then
    install_apps $setup_platform
    config_setup $setup_platform
    git_setup
  fi

  if [[ "$git_setup" == true ]]; then
    git_setup
  fi

  if [[ "$install" == true ]]; then
    install_apps $setup_platform
  fi

  if [[ "$config_setup" == true ]]; then
    config_setup $setup_platform
  fi

  change_shopt false
}

main "$@"
