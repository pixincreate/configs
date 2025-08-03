#!/bin/bash

echo "=== System Health Check ==="
echo "Date: $(date)"
echo

echo "=== CPU Temperature ==="
sensors | grep "Core"

echo "=== GPU Temperature ==="
nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits

echo "=== Memory Usage ==="
free -h

echo "=== Disk Usage ==="
df -h | grep -E '^/dev/'

echo "=== System Load ==="
uptime

echo "=== Failed Services ==="
systemctl --failed

echo "=== Recent Errors ==="
journalctl --since "1 hour ago" --priority=err --no-pager | tail -10
