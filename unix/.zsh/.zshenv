typeset -U PATH path
path=(
  $path
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
)

# Set XDG base directories

# User directories
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share

# System directories (`:` separated list of directories)
export XDG_DATA_DIRS=/usr/local/share:/usr/share
export XDG_CONFIG_DIRS=/etc/xdg

export PKG_CONFIG_PATH="$(brew --prefix)/Cellar/e2fsprogs/1.47.1/lib/pkgconfig"

# Specify the directory for user-specific non-essential data files
export CONFIGS=${HOME}/Dev/scripts/configs

# Set default editor
export EDITOR=nvim
export VISUAL=nvim
