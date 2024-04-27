#!/bin/sh

additional_zshrc() {
  echo '
    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

    # Source init for Docker
    source $HOME/.docker/init-zsh.sh || true # Added by Docker Desktop

    # Disable NPM ads
    export DISABLE_OPENCOLLECTIVE=1
    export ADBLOCK=1

    PQ_LIB_DIR="$(brew --prefix libpq)/lib"
  ' >> ~/.zsh/.zshrc
}

brew_install() {
  echo -e "\nInstalling brew..."

  yes '' | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo -e "\nAdding brew to Linux PATH..."
    mkdir -p ~/.zsh

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
    croc \
    direnv \
    gcc

  brew install \
    git-delta \
    micro \
    neofetch

  brew install \
    neovim # Because neovim has too many dependencies

  brew install \
    openssh

  brew install \
    sqlite \
    starship

  brew install \
    fzf \
    tree \
    walk \
    zoxide

  # Tools
  brew install \
    docker \
    nextdns/tap/nextdns \
    node \
    rustup-init \
    topgrade
}

linux() {
  echo -e "\nInstalling for Linux..."
  # Install brew and other packages
  brew_install

  echo -e "Installation successful!"

  # WSL Git Setup
  if [[ "$WSL_DISTRO_NAME" == "Debian" ]]; then
    echo -e "\nSetting up git for WSL..."
    export WINHOME=$(wslpath $(powershell.exe '$env:USERPROFILE' | tr -d '\r'))
    mkdir -p "$HOME/.ssh"
    cp $WINHOME/.ssh/id_ed25519_auth $HOME/.ssh/id_ed25519_auth
    cp $WINHOME/.ssh/id_ed25519_auth.pub $HOME/.ssh/id_ed25519_auth.pub

    cp $WINHOME/.ssh/id_ed25519_sign $HOME/.ssh/id_ed25519_sign
    cp $WINHOME/.ssh/id_ed25519_sign.pub $HOME/.ssh/id_ed25519_sign.pub

    chmod 0600 .ssh/*

    echo -e "WSL setup completed!"

    # Install VSCode server
    code

    echo '' >> ~/.zshrc
    echo 'export WINHOME=\$(wslpath \$(powershell.exe '\$env:USERPROFILE' | tr -d '\\\\r'))' >> ~/.zshrc
  fi
  additional_zshrc
}

android() {
  echo -e "\nInstalling for Andoird..."
  echo -e "Make sure that you've installed Termux and Shizuku."

  # Make a folder for Shizuku rish files
  mkdir -p ~/.rish

  # Brew is unsupported in Android (Termux)
  pkg update && pkg install \
    android-tools \
    croc \
    direnv \
    fzf \
    git \
    git-delta \
    micro \
    neofetch \
    neovim \
    openssh \
    sqlite \
    starship \
    tar \
    topgrade \
    tree \
    tsu \
    termux-am \
    zoxide

  termux-setup-storage

  (
    echo
    echo -e "alias backup_termux='tar -zcf /sdcard/backups/termux/termux-backup.tar.gz -C /data/data/com.termux/files ./home ./usr'"
    echo -e "alias restore_termux='tar -zxf /sdcard/backups/termux/termux-backup.tar.gz -C /data/data/com.termux/files --recursive-unlink --preserve-permissions'"
  ) >> ~/.zsh/.zshrc

  # Make sure that you've exported rish files from Shizuku app
  cp /storage/emulated/0/Documents/Shizuku/* $HOME/.rish/*
  ln -s $HOME/.rish/rish $PATH/rish
  ln -s $HOME/.rish/rish_shizuku.dex $PATH/rish_shizuku.dex

  echo -e "Installation successful!"
}

mac() {
  echo -e "\nInstalling for Mac..."
  brew_install
  echo -e "Installation successful!"
  additional_zshrc
}

main() {
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
  rm $HOME/dotfiles.sh

  case $OSTYPE in
    linux* | linux-android)
      mv $HOME/Code $HOME/.config/Code
      ;;
    darwin*)
      mv $HOME/Code "$HOME/Library/Application\ Support/Code"
      ;;
  esac

  # Create zgenom directory (just to not be error prone) and change the default shell to zsh
  echo -e "\nSetting up zshell..."
  mkdir -p ~/.zsh/zgenom
  sudo chsh -s $(which zsh) $(whoami)

  starship preset pastel-powerline -o ~/.config/starship.toml

  # Delete the downloaded repository
  rm -rf configs

  echo -e "\n\nInstallation successful!"
  echo -e "Please restart your terminal to see the changes."
  echo
}

main
