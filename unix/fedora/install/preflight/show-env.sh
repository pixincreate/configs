#!/bin/bash
# Show installation environment variables

log_info "Installation Environment:"

env | grep -E "^(OMAFORGE_GIT_NAME|OMAFORGE_GIT_EMAIL|OMAFORGE_NEXTDNS_ID|OMAFORGE_SECUREBOOT|OMAFORGE_REPO|OMAFORGE_REF|OMAFORGE_PATH|OMAFORGE_INSTALL|OMAFORGE_CONFIG|USER|HOME)=" | sort | while IFS= read -r var; do
  log_info "  $var"
done
