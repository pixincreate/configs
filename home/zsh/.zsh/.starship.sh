# Detect the current running shell, not the default shell
if [ -n "$ZSH_VERSION" ]; then
    CURRENT_SHELL="zsh"
elif [ -n "$BASH_VERSION" ]; then
    CURRENT_SHELL="bash"
else
    # Fallback to checking the process name
    CURRENT_SHELL=$(basename "$0" 2>/dev/null || echo "unknown")
fi


export STARSHIP_PRESETS_DIR="${HOME}/.config/starship/presets"
STARSHIP_STATE_FILE="$STARSHIP_PRESETS_DIR/current_preset"


if [ "$CURRENT_SHELL" = "zsh" ]; then
    # Define the transient prompt (minimal version)
    function _starship_transient_prompt() {
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

    function starship_transient_prompt_setup() {
        # Register the ZLE widgets only if zle is available
        if [[ -n "$ZSH_VERSION" ]] && (($+widgets)); then
            zle -N zle-line-finish _starship_zle_line_finish
            zle -N zle-line-init _starship_zle_line_init
        fi
    }

    # Remove the setup function after first run to avoid re-registering
    function starship_transient_prompt_setup_once() {
        starship_transient_prompt_setup
        # Remove this function from precmd hooks after first run
        add-zsh-hook -d precmd starship_transient_prompt_setup_once
    }
fi


case "$CURRENT_SHELL" in
    "zsh")
        eval "$(starship init zsh)"

        # Transient prompt implementation for Starship (ZSH only)
        if command -v starship >/dev/null 2>&1; then
            # Set up the transient prompt in precmd hook to ensure proper timing
            autoload -Uz add-zsh-hook
            add-zsh-hook precmd starship_transient_prompt_setup
            add-zsh-hook precmd starship_transient_prompt_setup_once
        fi
        ;;
    "bash")
        eval "$(starship init bash)"
        ;;
    *)
        if command -v starship >/dev/null 2>&1; then
            eval "$(starship init "$CURRENT_SHELL" 2>/dev/null || starship init bash)"
        fi
        ;;
esac


if [ ! -d "$STARSHIP_PRESETS_DIR" ]; then
    mkdir -p "$STARSHIP_PRESETS_DIR"
fi


if [ -f "$STARSHIP_STATE_FILE" ]; then
    current_preset=$(cat "$STARSHIP_STATE_FILE" 2>/dev/null)
    preset_path="$STARSHIP_PRESETS_DIR/$current_preset.toml"
    if [ -f "$preset_path" ]; then
        export STARSHIP_CONFIG="$preset_path"
    else
        # Preset file missing, clean up and use default
        rm -f "$STARSHIP_STATE_FILE" 2>/dev/null
        export STARSHIP_CONFIG="$STARSHIP_PRESETS_DIR/default.toml"
    fi
else
    export STARSHIP_CONFIG="$STARSHIP_PRESETS_DIR/default.toml"
fi


switch_starship_preset() {
    local name="$1"
    local path="$STARSHIP_PRESETS_DIR/$name.toml"

    if [ -z "$name" ]; then
        echo "Usage: switch_starship_preset <preset_name>"
        echo "Available presets:"
        if [ -d "$STARSHIP_PRESETS_DIR" ]; then
            for preset in "$STARSHIP_PRESETS_DIR"/*.toml; do
                if [ -f "$preset" ]; then
                    # Extract filename without path and .toml extension
                    preset_name="${preset##*/}"
                    preset_name="${preset_name%.toml}"
                    echo "  $preset_name"
                fi
            done
        fi
        return 1
    fi

    if [ ! -f "$path" ]; then
        echo "No such preset: $name"
        echo "Available presets:"
        if [ -d "$STARSHIP_PRESETS_DIR" ]; then
            for preset in "$STARSHIP_PRESETS_DIR"/*.toml; do
                if [ -f "$preset" ]; then
                    # Extract filename without path and .toml extension
                    preset_name="${preset##*/}"
                    preset_name="${preset_name%.toml}"
                    echo "  $preset_name"
                fi
            done
        fi
        return 1
    fi

    echo "$name" > "$STARSHIP_STATE_FILE"
    export STARSHIP_CONFIG="$path"

    case "$CURRENT_SHELL" in
        "zsh")
            echo "Preset switched to: $name"
            # Re-initialize starship with new config instead of full shell restart
            if command -v starship >/dev/null 2>&1; then
                eval "$(starship init zsh)"
                # Re-setup transient prompt if it was enabled
                if typeset -f starship_transient_prompt_setup >/dev/null 2>&1; then
                    starship_transient_prompt_setup
                fi
            fi
            ;;
        "bash")
            echo "Preset switched to: $name"
            # Re-initialize starship with new config
            if command -v starship >/dev/null 2>&1; then
                eval "$(starship init bash)"
            fi
            ;;
        *)
            echo "Preset switched to: $name"
            echo "Please restart your shell or re-source your config to apply changes"
            ;;
    esac
}


alias spreset='switch_starship_preset'
