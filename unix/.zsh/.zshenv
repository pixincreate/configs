typeset -U PATH path
path=(
  $path
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$(brew --prefix)/opt/coreutils/libexec/gnubin"
)
export EDITOR=micro
export VISUAL=micro
