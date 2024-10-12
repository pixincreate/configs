# A function to check if a command exists
command_exists() {
  command -v "$1" > /dev/null 2>&1
}

if [[ "$TERM" = "alacritty" ]]; then
  if [[ "${MUX}" == "zellij" ]]; then
    if command -v zellij &> /dev/null; then
      # List Zellij sessions
      ZJ_SESSIONS=$(zellij list-sessions)
      NO_SESSIONS=$(echo "${ZJ_SESSIONS}" | wc -l)

      # Attach to the main session or create a new one if none exists
      if [[ "${NO_SESSIONS}" -gt 2 ]]; then
        # Attach to any session using fzf if no 'main' session exists
        zellij attach "$(echo "${ZJ_SESSIONS}" | fzf)"
      elif echo "${ZJ_SESSIONS}" | grep -q 'main'; then
        # Check if currently in the 'main' session
        if ! [[ "$ZELLIJ" == 0 ]] && ! [[ "$ZELLIJ_SESSION_NAME" == "main" ]]; then
          zellij attach main
        fi
      else
        zellij attach -c main
      fi
      # Setup Zellij completions and environment
      source <(zellij setup --generate-completion zsh | sed '/_zellij "$@"/d')
    else
      echo "Package zellij is missing!"
    fi
  elif [[ "${MUX}" == "tmux" ]]; then
    if command -v tmux &> /dev/null; then
      if [ -z "${TMUX}" ]; then
        if tmux ls | grep -qv attached; then
          exec tmux attach
        else
          exec tmux new-session
        fi
      fi
    else
      echo "Package tmux is missing!"
    fi
  fi
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
    autoload -Uz compinit
    compinit
fi

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
zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"

# History
export HISTFILE="$ZDOTDIR/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=10000

# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Options
setopt append_history         # Append history list to the history file, rather than replace it
setopt inc_append_history     # Write to the history file immediately, not when the shell exits
setopt share_history          # Share history between all sessions
setopt hist_expire_dups_first # Expire a duplicate event first when trimming history
setopt hist_ignore_dups       # Do not record an event that was just recorded again
setopt hist_ignore_all_dups   # Delete an old recorded event if a new event is a duplicate
setopt hist_find_no_dups      # Do not display a previously found event
setopt hist_ignore_space      # Do not record an event starting with a space
setopt hist_save_no_dups      # Do not write a duplicate event to the history file
setopt hist_verify            # Do not execute immediately upon history expansion
setopt extended_history       # Show timestamp in history
setopt extended_glob          # Use extended globbing
setopt auto_cd                # Automatically change directory if a directory is entered
setopt notify                 # Report the status of background jobs immediately

# Aliases
alias cd='z'
alias ls='eza -lh --group-directories-first --icons --hyperlink'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ll='ls --color=auto -l --almost-all --human-readable'
alias df='df --human-readable'
alias du='du --human-readable'
alias exal='exa --long --all --binary --header'
alias ip='ip --color'
alias ncdu='ncdu -rr --color dark'
alias cat='bat'
alias rm='trash -v'
alias mkdir='mkdir -p'
alias grep='grep --color=auto'
alias cls='clear'
alias multitail='multitail --no-repeat -c'
alias vi='nvim'
alias reload='echo "Reloading shell...";sleep 1;clear;exec ${SHELL} -l'
alias inv='nvim $(fzf -m --preview="bat --color=always {}")'  # Open files in nvim with fzf

# Tmux aliases
alias tmux_debug='tmux kill-server && tmux -f ~/.config/tmux/tmux.conf > tmux.log 2>&1'
alias tmux_attach='tmux attach -d -t' # Attach to a detached session. Usage: tmux_attach <session_name/id>
alias tmux_switch='tmux switch-client -t' # Switch to another client. Usage: tmux_switch <session_name/id>
alias tmux_kill_session='tmux kill-session -t' # Kill a session. Usage: tmux_killsession <session_name/id>

# Zellij aliases
alias zj='zellij'
alias zrf='zj run -f -- '

## Directory aliases
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

### Remove a directory and all files
alias rmd='/bin/rm  --recursive --force --verbose '

### Alias's for multiple directory listing commands
alias la='ls -Alh'                # show hidden files
alias ls='ls -aFh --color=always' # add colors and file type extensions
alias lx='ls -lXBh'               # sort by extension
alias lk='ls -lSrh'               # sort by size
alias lc='ls -lcrh'               # sort by change time
alias lu='ls -lurh'               # sort by access time
alias lr='ls -lRh'                # recursive ls
alias lt='ls -ltrh'               # sort by date
alias lm='ls -alh |more'          # pipe through 'more'
alias lw='ls -xAh'                # wide listing format
alias ll='ls -Fls'                # long listing format
alias labc='ls -lap'              #alphabetical sort
alias lf="ls -l | egrep -v '^d'"  # files only
alias ldir="ls -l | egrep '^d'"   # directories only

## Alias's to show disk space and space used in a folder
alias diskspace="du -S | sort -n -r |more"
alias folders='du -h --max-depth=1'
alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias treef='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -hT'

## Alias's for archives
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

## SHA1
alias sha1='openssl sha1'

## Search files in the current folder
alias f="find . | grep "

## Count all files (recursively) in the current folder
alias countfiles="for t in files links directories; do echo \`find . -type \${t:0:1} | wc -l\` \$t; done 2> /dev/null"

## To see if a command is aliased, a file, or a built-in command
alias checkcommand="type -t"

## Show open ports
alias openports='netstat -nape --inet'

# IP address lookup
alias whatismyip="whatsmyip"

# Linux version of OSX pbcopy and pbpaste
if [[ "$OSTYPE" == "linux-gnu" ]]; then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
elif [[ "$OSTYPE" == "linux-android" ]]; then
  alias pbcopy='termux-clipboard-set $1'
  alias pbpaste='termux-clipboard-get'
fi


# Auto update this file
update_zshrc() {
  force_update=false

  # Check if --force flag is provided
  if [[ "$1" == "--force" ]]; then
    force_update=true
  fi

  if wget -q --spider http://duck.com; then
    local url="https://github.com/pixincreate/configs/raw/main/unix/.zsh/.zshrc"
    local zshrc_file="${HOME}/.zsh/.zshrc"
    local temp_file=$(mktemp)

    curl -sSL "$url" -o "$temp_file"

    if [[ "$force_update" == true ]]; then
      # Force update without checksum comparison
      echo -ne "Updating .zshrc...\r"
      mv -f "$zshrc_file" "${zshrc_file}.bak"
      mv -f "$temp_file" "$zshrc_file"
      echo -e ".zshrc updated successfully!"
      source "$zshrc_file"
    else
      # Perform checksum comparison
      local current_checksum=$(sha1sum "$zshrc_file" | awk '{print $1}')
      local new_checksum=$(sha1sum "$temp_file" | awk '{print $1}')

      if [[ "$current_checksum" != "$new_checksum" ]]; then
        echo -ne "Updating .zshrc...\r"
        mv -f "$zshrc_file" "${zshrc_file}.bak"
        mv -f "$temp_file" "$zshrc_file"
        echo -e ".zshrc updated successfully!"
        source "$zshrc_file"
      else
        echo ".zshrc is up-to-date!"
        rm "$temp_file"
      fi
    fi
  else
    echo "Failed to update .zshrc!"
  fi
}

update_zshrc

function whatsmyip() {
  # Internal IP Lookup.
  if [ -e /sbin/ip ]; then
    echo -n "Internal IP: "
    /sbin/ip addr show wlan0 | grep "inet " | awk -F: '{print $1}' | awk '{print $2}'
  else
    echo -n "Internal IP: "
    /sbin/ifconfig wlan0 | grep "inet " | awk -F: '{print $1} |' | awk '{print $2}'
  fi

  # External IP Lookup
  echo -n "External IP: "
  curl -s ifconfig.me
}
# Extracts any archive(s) (if unp isn't installed)
extract() {
  for archive in "$@"; do
    if [ -f "$archive" ]; then
      case $archive in
        *.tar.bz2) tar xvjf $archive ;;
        *.tar.gz) tar xvzf $archive ;;
        *.bz2) bunzip2 $archive ;;
        *.rar) rar x $archive ;;
        *.gz) gunzip $archive ;;
        *.tar) tar xvf $archive ;;
        *.tbz2) tar xvjf $archive ;;
        *.tgz) tar xvzf $archive ;;
        *.zip) unzip $archive ;;
        *.Z) uncompress $archive ;;
        *.7z) 7z x $archive ;;
        *) echo "don't know how to extract '$archive'..." ;;
      esac
    else
      echo "'$archive' is not a valid file!"
    fi
  done
}

# Automatically do an ls after each cd, z, or zoxide
z() {
  if [ -n "$1" ]; then
    builtin cd "$@" && ls
  else
    builtin cd ~ && ls
  fi
}

# Returns the last 2 fields of the working directory
pwdtail() {
  pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# Copy file with a progress bar
cpp() {
  set -e
  strace -q -ewrite cp -- "${1}" "${2}" 2>&1 \
    | awk '{
	count += $NF
	if (count % 10 == 0) {
		percent = count / total_size * 100
		printf "%3d%% [", percent
		for (i=0;i<=percent;i++)
			printf "="
			printf ">"
			for (i=percent;i<100;i++)
				printf " "
				printf "]\r"
			}
		}
	END { print "" }' total_size="$(stat -c '%s' "${1}")" count=0
}

# Copy and go to the directory
cpg() {
  if [ -d "$2" ]; then
    cp "$1" "$2" && cd "$2"
  else
    cp "$1" "$2"
  fi
}

# Move and go to the directory
mvg() {
  if [ -d "$2" ]; then
    mv "$1" "$2" && cd "$2"
  else
    mv "$1" "$2"
  fi
}

# Create and go to the directory
mkdirg() {
  mkdir -p "$1"
  cd "$1"
}

# Goes up a specified number of directories  (i.e. up 4)
up() {
  local d=""
  limit=$1
  for ((i = 1; i <= limit; i++)); do
    d=$d/..
  done
  d=$(echo $d | sed 's/^\///')
  if [ -z "$d" ]; then
    d=..
  fi
  cd $d
}

# Tmux specific functions
function rsc() {
  CLIENTID=$1.`date +%S`
  tmux new-session -d -t $1 -s $CLIENTID \; set-option destroy-unattached \; attach-session -t $CLIENTID
}

function mksc() {
  tmux new-session -d -s $1
  rsc $1
}

# ZGenom
if [[ ! -f "$ZDOTDIR/.zgenom/zgenom.zsh" ]]; then
  command git clone https://github.com/jandamm/zgenom.git "$ZDOTDIR/.zgenom"
  command mkdir -p "$ZDOTDIR" && command chmod g-rwX "$ZDOTDIR/.zgenom"
fi

# Source zgenom
source "${ZDOTDIR}/.zgenom/zgenom.zsh"

# Check for plugin and zgenom updates every 7 days
# This does not increase the startup time.
zgenom autoupdate

# use zgenom reset to delete init.zsh
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

  # Powerlevel10k
  zgenom load romkatv/powerlevel10k powerlevel10k

  # LS_COLORS
  zgenom load trapd00r/LS_COLORS lscolors.sh

  # Plugins files from zsh-users
  zgenom load zsh-users/zsh-syntax-highlighting
  zgenom load zsh-users/zsh-autosuggestions
  zgenom load zsh-users/zsh-completions

  # Save plugins to init script
  zgenom save

  # Compile files
  zgenom compile "${ZDOTDIR}/zgenom/zgenom.zsh"
fi

# zoxide
eval "$(zoxide init zsh)"

# direnv
eval "$(direnv hook zsh)"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Source Powerlevel10k configuration
source "${ZDOTDIR}/.p10k.zsh"

# Load application aliases
[[ -f ~/.zsh/.additionals.zsh ]] && source ~/.zsh/.additionals.zsh
