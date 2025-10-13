#!/bin/bash
# Hardware detection and configuration

echo "Detecting and configuring hardware"

source "$OMAFORGE_INSTALL/config/hardware/asus.sh"
source "$OMAFORGE_INSTALL/config/hardware/nvidia.sh"

log_success "Hardware configuration completed"
