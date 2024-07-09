#!/usr/bin/env bash

git submodule init
git submodule update

# what directories should be installable by all users including the root user
base=(
  bash
)

# folders that should, or only need to be installed for a local user
useronly=(
  git
)

# run the stow command for the passed in directory ($2) in location $1
stowit() {
  usr=$1
  app=$2
  # -v verbose
  # -R recursive
  # -t target
  stow -v -R -t ${usr} ${app}
}

echo ""
echo "Stowing for user: ${whoami}"

# install apps available to local users and root
for app in ${base[@]}; do
  stowit "${HOME}" $app
done

# install only user space folders
for app in ${useronly[@]}; do
  if [[! "$(whoami)" = *"root"*]]; then
    stowit "${HOME}" $app
  fi
done
