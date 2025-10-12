#!/bin/bash

source "$FEDORA_INSTALL/helpers/logging.sh"

log_section "Web Applications"

# Ensure bin directory is in PATH for the session
export PATH="$FEDORA_PATH/bin:$PATH"

# Twitter/X
log_info "Installing Twitter web app..."
omaforge-webapp-install "Twitter" \
  "https://x.com/" \
  "https://abs.twimg.com/responsive-web/client-web/icon-ios.77d25eba.png"

# ChatGPT (Incognito mode)
log_info "Installing ChatGPT web app (incognito)..."
omaforge-webapp-install "ChatGPT" \
  "https://chatgpt.com/" \
  "https://cdn.oaistatic.com/_next/static/media/apple-touch-icon.59f2e898.png" \
  "omaforge-launch-browser --private https://chatgpt.com/"

# Grok (Incognito mode)
log_info "Installing Grok web app (incognito)..."
omaforge-webapp-install "Grok" \
  "https://x.com/i/grok" \
  "https://abs.twimg.com/responsive-web/client-web/icon-ios.77d25eba.png" \
  "omaforge-launch-browser --private https://x.com/i/grok"

log_success "Web applications installed"
