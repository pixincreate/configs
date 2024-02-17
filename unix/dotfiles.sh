#!/bin/sh

cp home/* ~/*

brew() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Turn brew analytics off
  brew analytics off

  # Since brew has most of the packages, it is easy to maintain
  brew install \
    croc \
    direnv \
    git-delta \
    micro \
    neovim \
    openssh \
    sqlite \
    starship \
    tree \
    walk \
    zoxide
}

unix() {
  # Install the necessities
  sudo apt-get update && sudo apt-get install \
    curl \
    zsh
}

linux() { 
  unix()
  brew()

  mv Code $HOME/.config/Code
}

android() {
  # Make a folder for Shizuku rish files
  mkdir -p ~/.rish

  # Brew is unsupported in Android (Termux)
  pkg update && pkg install \
    android-tools \
    croc \
    direnv \
    git-delta \
    micro \
    neovim \
    openssh \
    sqlite \
    starship \
    tar \
    tree \
    tsu \
    termux-am \
    zoxide

  unix()

  termux-setup-storage

  # Make sure that you've exported rish files from Shizuku app
  cp /storage/emulated/0/Documents/Shizuku/* $HOME/.rish/*
  ln -s $HOME/.rish/rish $PATH/rish
  ln -s $HOME/.rish/rish_shizuku.dex $PATH/rish_shizuku.dex
}

mac() {
  brew()

  mv Code $HOME/Library/Application\ Support/Code
}

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  linux
elif [[ "$OSTYPE" == "darwin" ]]; then
  mac
elif [[ "$OSTYPE" == "linux-android" ]]; then
  android
fi

# Create zgenom directory (just to not be error prone) and change the default shell to zsh
mkdir -p ~/.zsh/zgenom && chsh -s zsh

starship preset pastel-powerline -o ~/.config/starship.toml
