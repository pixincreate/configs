#!/bin/bash
# Common helper functions for macOS setup

cmd_exists() {
    command -v "$1" &>/dev/null
}

run_logged() {
    local script="$1"
    log_info "Running: $(basename "$script")"
    source "$script"
}

confirm() {
    local prompt="$1"
    local default="${2:-N}"

    # Non-interactive mode
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        if [[ "$default" == "Y" ]]; then
            log_info "$prompt [NON_INTERACTIVE: Yes]"
            return 0
        else
            log_info "$prompt [NON_INTERACTIVE: No]"
            return 1
        fi
    fi

    if [[ "$default" == "Y" ]]; then
        read -p "$prompt [Y/n] " -n 1 -r
    else
        read -p "$prompt [y/N] " -n 1 -r
    fi

    echo

    if [[ "$default" == "Y" ]]; then
        [[ ! $REPLY =~ ^[Nn]$ ]]
    else
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# JSON configuration helpers using jq
get_config() {
    local key="$1"
    jq -r "$key // empty" "$MACOS_CONFIG" 2>/dev/null
}

get_config_array() {
    local key="$1"
    jq -r "$key[]? // empty" "$MACOS_CONFIG" 2>/dev/null
}

expand_path() {
    local path="$1"
    eval echo "$path"
}
