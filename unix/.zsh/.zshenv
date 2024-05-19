typeset -U PATH path
path=(
  $path
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
)
export EDITOR=micro
export VISUAL=micro
