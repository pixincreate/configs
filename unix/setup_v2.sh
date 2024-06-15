#!/bin/bash

REPO_URL="https://github.com/pixincreate/configs.git"
CLONE_DIR="${HOME}/configs"

# Clone the repository if it does not exist
if [ ! -d "${CLONE_DIR}" ]; then
  git clone "${REPO_URL}" "${CLONE_DIR}"
else
  echo "Repository already cloned."
fi

# Create a symlink for .config if it does not exist
if [ ! -L "${TARGET_LINK}" ]; then
  ln -s "${CONFIG_DIR}" "${TARGET_LINK}"
  echo "Symlink created: ${TARGET_LINK} -> ${CONFIG_DIR}"
else
  echo "Symlink already exists: ${TARGET_LINK}"
fi

ln -s "${CLONE_DIR}/unix/.zsh" "${HOME}/.zsh"
ln -s "${CLONE_DIR}/unix/.zshenv" "${HOME}/.zshenv"
ln -s "${CLONE_DIR}/home/*" "${HOME}/*"

# TODO: .gitconfig setup
# TODO: Android, Linux and macOS setup E2E
