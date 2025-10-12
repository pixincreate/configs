#!/bin/bash
# Presentation helpers for Fedora setup
# Terminal UI functions

clear_screen() {
    # Use printf instead of clear for better compatibility
    printf "\033c"
}

show_logo() {
    clear_screen
    cat << 'EOF'
 ▄██████▄    ▄▄▄▄███▄▄▄▄      ▄████████    ▄████████  ▄██████▄     ▄████████    ▄██████▄     ▄████████
███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███   ███    ███ ███    ███   ███    ███   ███    ███   ███    ███
███    ███ ███   ███   ███   ███    ███   ███    █▀  ███    ███   ███    ███   ███    █▀    ███    █▀
███    ███ ███   ███   ███   ███    ███  ▄███▄▄▄     ███    ███  ▄███▄▄▄▄██▀  ▄███         ▄███▄▄▄
███    ███ ███   ███   ███ ▀███████████ ▀▀███▀▀▀     ███    ███ ▀▀███▀▀▀▀▀   ▀▀███ ████▄  ▀▀███▀▀▀
███    ███ ███   ███   ███   ███    ███   ███        ███    ███ ▀███████████   ███    ███   ███    █▄
███    ███ ███   ███   ███   ███    ███   ███        ███    ███   ███    ███   ███    ███   ███    ███
 ▀██████▀   ▀█   ███   █▀    ███    █▀    ███         ▀██████▀    ███    ███   ████████▀    ██████████
                                                                  ███    ███
EOF
    echo ""
}

show_welcome() {
    show_logo
    echo "Declarative Fedora Setup System"
    echo ""
    echo "This will configure your Fedora system with:"
    echo "  - Optimized repositories (RPM Fusion, COPR, Terra)"
    echo "  - Development tools and applications"
    echo "  - System optimizations and hardware detection"
    echo "  - Dotfiles and configurations"
    echo ""
}
