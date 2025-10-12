#!/bin/bash
# Hardware detection and configuration

echo "Detecting and configuring hardware"

source "$FEDORA_INSTALL/config/hardware/asus.sh"
source "$FEDORA_INSTALL/config/hardware/nvidia.sh"

log_success "Hardware configuration completed"
