typeset -U PATH path
path=(
  $path
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
)

# User directories
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share

# System directories (`:` separated list of directories)
export XDG_DATA_DIRS=/usr/local/share:/usr/share
export XDG_CONFIG_DIRS=/etc/xdg

# Specify the directory for user-specific non-essential data files
export CONFIGS=${HOME}/Dev/scripts/configs

# Set default editor
export EDITOR=nvim
export VISUAL=nvim

# Source env from cargo
# . "$HOME/.cargo/env"

# Set mux to run
export MUX='zellij'
