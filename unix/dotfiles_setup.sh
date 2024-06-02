#!/bin/sh

dir_setup() {
  mkdir -p \
    ~/.config \
    ~/.rish \
    ~/.ssh \
    ~/.zsh \
    ~/.zsh/.zgenom
}

replace_gitconfig_data() {
  sed -i.bak 's/email = example@email.com/email = 69745008+pixincreate@users.noreply.github.com/' ~/.gitconfig
  sed -i.bak 's/name = username/name = PiX/' ~/.gitconfig
  sed -i.bak 's|signingkey = ~/.ssh/signingkey|signingkey = ~/.ssh/id_ed25519_sign.pub|' ~/.gitconfig
}

git_setup() {
  echo "Fresh setup Git or restore existing configuration?"
  select confirm in "Fresh setup" "Restore existing"; do
    case $confirm in
      "Fresh setup" )
        # Fresh setup (if selected)
        echo "Performing fresh Git setup..."
        
        # Prompt for user details (single loop)
        while [[ -z "$user_name" || -z "$user_email" || -z "$private_email" ]]; do
          read -p "Enter your user name for configuring git: " user_name
          read -p "Enter your email for configuring git: " user_email
          read -p "Enter your no-reply email for configuring git: " private_email
          
          # Validate non-empty and non-whitespace
          if [[ -z "$user_name" || "$user_name" =~ ^[[:space:]]*$ ]]; then
            echo "Username cannot be empty or whitespace."
          fi
          if [[ -z "$user_email" || "$user_email" =~ ^[[:space:]]*$ ]]; then
            echo "Email cannot be empty or whitespace."
          fi
          if [[ -z "$private_email" || "$private_email" =~ ^[[:space:]]*$ ]]; then
            echo "No-reply email cannot be empty or whitespace."
          fi
        done
        
        replace_gitconfig_data
        generate_ssh_keys "$user_email"
        copy_and_update_keys
        break
        ;;
      "Restore existing" )
        # Restore existing configuration
        echo "Restoring existing Git configuration..."
        replace_gitconfig_data
        break
        ;;
      * )
        echo "Invalid selection. Please choose '1' for fresh setup or '2' to restore existing git configuration."
        ;;
    esac
  done
}

# Function to generate SSH keys (DRY principle)
generate_ssh_keys() {
  local email="$1"
  auth_path="~/.ssh/id_ed25519_auth"
  sign_path="~/.ssh/id_ed25519_sign"

  echo "Path to authentication file: ${auth}"
  echo "Path to signature file: ${sign}"
  
  ssh-keygen -t ed25519 -C "$email" -f "$auth_path"
  eval "$(ssh-agent -s)"
  ssh-keygen -t ed25519 -C "$email" -f "$sign_path"
  eval "$(ssh-agent -s)"

  ssh-add "$auth_path"
  ssh-add "$sign_path"
}

# Function to copy keys and prompt (DRY principle)
copy_and_update_keys() {
  auth_path="~/.ssh/id_ed25519_auth"
  sign_path="~/.ssh/id_ed25519_sign"
  
  pbcopy < "$auth_path"
  echo "You have 3 minutes to visit https://github.com/settings/keys and update keys on GitHub."
  echo "Update the Authentication key"
  sleep 180
  pbcopy < "$sign_path"
  echo "Update the Signature key"
  sleep 180
  
  ssh -T git@github.com
}

additional_zshrc() {
  echo '
    # Dev env variables
    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"

    # Source init for Docker
    source $HOME/.docker/init-zsh.sh || true

    # Disable NPM ads
    export DISABLE_OPENCOLLECTIVE=1
    export ADBLOCK=1

    PQ_LIB_DIR="$(brew --prefix libpq)/lib"
  ' >> ~/.zsh/.additionals.zsh
}

brew_install() {
  echo -e "\nInstalling brew..."
  yes '' | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo -e "\nAdding brew to Linux PATH..."

    (
      echo
      echo -e 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    ) >> ~/.bashrc

    (
      echo
      echo -e 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    ) >> ~/.zsh/.zprofile

    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

    # Install the necessities for brew
    sudo apt-get install -y build-essential

  elif [[ "$OSTYPE" == "darwin" ]]; then
    echo -e "\nAdding brew to Mac PATH..."

    (
      echo
      echo -e 'eval "$(/opt/homebrew/bin/brew shellenv)"'
    ) >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  # Turn brew analytics off
  brew analytics off

  echo -e "Brew install successful\nInstalling brew packages..."

  # Since brew has most of the packages, it is easy to maintain
  # Install the packages in batches
  brew install \
    bat \
    coreutils \
    croc \
    direnv \
    gcc

  brew install \
    git-delta \
    fastfetch \
    micro

  brew install \
    neovim # Because neovim has too many dependencies

  brew install \
    multitail \
    openssh

  brew install \
    sqlite \
    starship

  brew install \
    fzf \
    tree \
    walk \
    xclip \
    zoxide

  # Tools
  brew install \
    docker \
    nextdns/tap/nextdns \
    node \
    rustup-init \
    topgrade \
    trash-cli
}

linux() {
  echo -e "\nInstalling for Linux..."
  # Install brew and other packages
  brew_install

  echo -e "Installation successful!"

  # WSL Git Setup
  if [[ "$WSL_DISTRO_NAME" == "Debian" ]]; then
    echo -e "\nSetting up git for WSL..."
    WINHOME=$(wslpath "$(cd /mnt/c && cmd.exe /C 'echo %USERPROFILE%' | tr -d '\r')")

    files="id_ed25519_auth id_ed25519_auth.pub id_ed25519_sign id_ed25519_sign.pub"
    for file in $files; do
      src="$WINHOME/.ssh/$file"
      dest="$HOME/.ssh/$file"

      if [ -f "$src" ]; then
        cp "$src" "$dest"
      else
        echo "File not found: $src"
      fi
    done

    chmod 0600 .ssh/*

    echo -e "WSL setup completed!"

    # Install VSCode server
    code

    echo '
    # WSL specific configurations
    export WINHOME=$(wslpath "$(cd /mnt/c && cmd.exe /C '\''echo %USERPROFILE%'\'' | tr -d '\''\r'\'')")
    ' >> ~/.zsh/.additionals.zsh
    echo "alias studio='/mnt/d/Program\ Files/IDE/Android\ Studio/bin/studio64.exe'" >> ~/.zsh/.additionals.zsh
  fi
  additional_zshrc
}

android() {
  echo -e "\nInstalling for Andoird..."
  echo -e "Make sure that you've installed Termux and Shizuku."

  # Brew is unsupported in Android (Termux)
  pkg install -y \
    android-tools \
    bat \
    binutils \
    croc \
    cronie \
    direnv \
    fastfetch \
    fzf \
    git-delta \
    micro \
    multitail \
    neovim \
    openssh \
    python \
    sqlite \
    starship \
    tar \
    topgrade \
    tree \
    which \
    zoxide

  pkg install -y \
    tsu \
    termux-tools \
    termux-api

  # Install other tools
  pip install trash-cli
  # Setup crontab to auto empty trash after 60 days
  (crontab -l ; echo "@daily $(which trash-empty) 60") | crontab -
  # List it for satisfaction
  crontab -l

  termux-setup-storage
  sleep 10

  echo "Setting up aliases for termux data backup and restore..."
  (
    echo
    echo -e "alias backup_termux='tar -zcf /sdcard/backups/termux/termux-backup.tar.gz -C /data/data/com.termux/files ./home ./usr'"
    echo -e "alias restore_termux='tar -zxf /sdcard/backups/termux/termux-backup.tar.gz -C /data/data/com.termux/files --recursive-unlink --preserve-permissions'"
  ) >> ~/.zsh/.additionals.zsh

  cp -a /storage/emulated/0/Documents/Dev/Shizuku/. $HOME/.rish/
  cp -a /storage/emulated/0/Documents/Dev/.ssh/. $HOME/.ssh/
  chmod 0600 .ssh/*

  ln -sfn $HOME/.rish/rish $PATH/rish
  ln -sfn $HOME/.rish/rish_shizuku.dex $PATH/rish_shizuku.dex

  echo -e "Installation successful!"
}

mac() {
  echo -e "\nInstalling for Mac..."
  brew_install
  echo -e "Installation successful!"
  additional_zshrc
}

main() {

  # Check for function argument and execute if provided
  if [[ "$@" == "git_setup" ]]; then
    "$@"
    exit
  fi

  # Create the necessary directories
  dir_setup

  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo -e "OS: Linux"
    linux
  elif [[ "$OSTYPE" == "darwin" ]]; then
    echo -e "OS: Mac"
    mac
  elif [[ "$OSTYPE" == "linux-android" ]]; then
    echo -e "OS: Android"
    android
  fi

  # Clone the configs repo and copy the files to the home directory
  echo -e "\nCloning the configs repo and copying the files to the home directory..."
  git clone https://github.com/pixincreate/configs.git
  cp -r configs/home/. $HOME
  cp -r configs/unix/. $HOME

  case $OSTYPE in
    linux* | linux-android)
      mv $HOME/Code $HOME/.config/Code
      ;;
    darwin*)
      mv $HOME/Code "$HOME/Library/Application\ Support/Code"
      ;;
  esac

  echo -e "\nSetting up zshell..."
  if [[ "$OSTYPE" == "linux-android" ]]; then
    chsh -s zsh
  else
    sudo chsh -s $(which zsh) $(whoami)
  fi

  mv -f configs/home/.config/starship.toml ~/.config/starship.toml

  # Delete the downloaded repository
  rm -rf configs

  git_setup

  echo -e "\n\nInstallation successful!"
  echo -e "Please restart your terminal to see the changes."
  echo
}

main
