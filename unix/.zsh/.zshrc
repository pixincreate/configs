
# Load colors
  autoload -U colors && colors

  # Zstyle
  zstyle ':completion:*:*:*:*:*' menu select
  zstyle ':completion:*:matches' group 'yes'
  zstyle ':completion:*:options' description 'yes'
  zstyle ':completion:*:options' auto-description '%d'
  zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
  zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
  zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
  zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
  zstyle ':completion:*:default' list-prompt '%S%M matches%s'
  zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
  zstyle ':completion:*' group-name ''
  zstyle ':completion:*' verbose yes
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path "$ZDOTDIR/.zcompcache"
  zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
  zstyle ':completion:*' rehash true

  # History
  export HISTFILE="$ZDOTDIR/.zsh_history"
  export HISTSIZE=50000
  export SAVEHIST=10000

  # Options
  setopt append_history           # Append history list to the history file, rather than replace it
  setopt inc_append_history       # Write to the history file immediately, not when the shell exits
  setopt share_history            # Share history between all sessions
  setopt hist_expire_dups_first   # Expire a duplicate event first when trimming history
  setopt hist_ignore_dups         # Do not record an event that was just recorded again
  setopt hist_ignore_all_dups     # Delete an old recorded event if a new event is a duplicate
  setopt hist_find_no_dups        # Do not display a previously found event
  setopt hist_ignore_space        # Do not record an event starting with a space
  setopt hist_save_no_dups        # Do not write a duplicate event to the history file
  setopt hist_verify              # Do not execute immediately upon history expansion
  setopt extended_history         # Show timestamp in history
  setopt extended_glob            # Use extended globbing
  setopt auto_cd                  # Automatically change directory if a directory is entered
  setopt notify                   # Report the status of background jobs immediately

  # Aliases
  alias ls='ls --color=auto'
  alias ll='ls --color=auto -l --almost-all --human-readable'
  alias df='df --human-readable'
  alias du='du --human-readable'
  alias cp='cp --verbose'
  alias mv='mv --verbose'
  alias ln='ln --verbose'
  alias exal='exa --long --all --binary --header'
  alias ip='ip --color'
  alias ncdu='ncdu -rr --color dark'

  alias ..='cd ..'
  alias ...='cd ../..'
  alias ....='cd ../../..'
  alias .....='cd ../../../..'
  alias ......='cd ../../../../..'

  alias vi=nvim

  # ZGenom
  if [[ ! -f $ZDOTDIR/zgenom/zgenom.zsh ]]; then
    command git clone https://github.com/jandamm/zgenom.git "$ZDOTDIR/zgenom"
    command mkdir -p "$ZDOTDIR" && command chmod g-rwX "$ZDOTDIR/zgenom"
  fi

  # Source zgenom
  source "${ZDOTDIR}/zgenom/zgenom.zsh"

  # If the zgenom init script doesn't exist
  if ! zgenom saved; then
    zgenom compdef

    # ohmyzsh keybindings
    zgenom ohmyzsh lib/key-bindings.zsh

    # Library files from ohmyzsh
    zgenom ohmyzsh lib/functions.zsh
    zgenom ohmyzsh lib/termsupport.zsh
    zgenom ohmyzsh plugins/git
    zgenom ohmyzsh plugins/gitignore

    # LS_COLORS
    zgenom load trapd00r/LS_COLORS lscolors.sh

    # Syntax highlighting
    zgenom load zsh-users/zsh-syntax-highlighting

    # Auto-suggestions
    zgenom load zsh-users/zsh-autosuggestions

    # Completions
    zgenom load zsh-users/zsh-completions

    # Save plugins to init script
    zgenom save

    # Compile files
    zgenom compile "${ZDOTDIR}/zgenom/zgenom.zsh"
  fi

  # Path to zsh completion scripts
  fpath=( $ZDOTDIR/.zfunc $fpath )

  # Load LS_COLORS
  zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"

  # zoxide
  eval "$(zoxide init zsh)"

  # direnv
  eval "$(direnv hook zsh)"

  # Starship
  eval "$(starship init zsh)"

  function lk {
    cd "$(walk "$@")"
  }
