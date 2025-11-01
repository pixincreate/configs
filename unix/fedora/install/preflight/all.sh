#!/bin/bash
set -eEuo pipefail
# Run all preflight checks

source "$OMAFORGE_INSTALL/preflight/show-env.sh"
source "$OMAFORGE_INSTALL/preflight/guard.sh"
