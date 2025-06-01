# Initialize Starship
eval "$(starship init zsh)"

# Transient prompt implementation for Starship (similar to P10k)
# This will replace the previous prompt with a simpler version after command execution
if command -v starship &>/dev/null; then
  # Define the transient prompt function
  function starship_transient_prompt_setup() {
    # Define the transient prompt (minimal version)
    function _starship_transient_prompt() {
      # Get the prompt character based on last command status
      local exit_code=$?
      local prompt_char
      if [[ $exit_code -eq 0 ]]; then
        prompt_char='%F{#a6e3a1}❯%f' # Green for success (Catppuccin Green)
      else
        prompt_char='%F{#f38ba8}❯%f' # Red for error (Catppuccin Red)
      fi

      # Set minimal transient prompt with newline for spacing
      PROMPT="$prompt_char "
      RPROMPT=''
    }

    # Function to restore full prompt
    function _starship_restore_prompt() {
      eval "$(starship init zsh)"
    }

    # Hook: Replace prompt with transient version after command execution
    function _starship_zle_line_finish() {
      _starship_transient_prompt
      zle reset-prompt
    }

    # Hook: Restore full prompt when starting to type a new command
    function _starship_zle_line_init() {
      # Only restore if we're starting a new command line
      if [[ -z "$BUFFER" ]]; then
        _starship_restore_prompt
        zle reset-prompt
      fi
    }

    # Register the ZLE widgets only if zle is available
    if [[ -n "$ZSH_VERSION" ]] && (($+widgets)); then
      zle -N zle-line-finish _starship_zle_line_finish
      zle -N zle-line-init _starship_zle_line_init
    fi
  }

  # Set up the transient prompt in precmd hook to ensure proper timing
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd starship_transient_prompt_setup

  # Remove the setup function after first run to avoid re-registering
  function starship_transient_prompt_setup_once() {
    starship_transient_prompt_setup
    # Remove this function from precmd hooks after first run
    add-zsh-hook -d precmd starship_transient_prompt_setup_once
  }
  add-zsh-hook precmd starship_transient_prompt_setup_once
fi
