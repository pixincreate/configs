#!/bin/bash

source "$OMAFORGE_INSTALL/helpers/logging.sh"

log_section "Web Applications"

# Ensure bin directory is in PATH for the session
export PATH="$OMAFORGE_PATH/bin:$PATH"

# ChatGPT (Incognito mode)
log_info "Installing ChatGPT web app (incognito)..."
omaforge-webapp-install "ChatGPT" \
  "https://chatgpt.com/" \
  "https://cdn.oaistatic.com/_next/static/media/apple-touch-icon.59f2e898.png" \
  "omaforge-launch-webapp https://chatgpt.com/ --incognito"

# Grok (Incognito mode)
log_info "Installing Grok web app (incognito)..."
omaforge-webapp-install "Grok" \
  "https://grok.com/" \
  "https://abs.twimg.com/responsive-web/client-web/icon-ios.77d25eba.png" \
  "omaforge-launch-webapp https://grok.com/ --incognito"

log_success "Web applications installed"
