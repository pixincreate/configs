#!/bin/bash

# Lock file to prevent concurrent executions and feedback loops
# Use XDG_RUNTIME_DIR (user-writable) instead of /run/lock (root-only)
LOCKFILE="${XDG_RUNTIME_DIR:-/tmp}/asus-profile-notify.lock"
STATEFILE="${XDG_RUNTIME_DIR:-/tmp}/asus-profile-last-state"
DEBOUNCEFILE="${XDG_RUNTIME_DIR:-/tmp}/asus-profile-debounce"

# Debounce: if script was run within last 0.5s, wait for things to settle
if [[ -f "$DEBOUNCEFILE" ]]; then
    last_run=$(cat "$DEBOUNCEFILE")
    current_time=$(date +%s%3N)  # milliseconds
    time_diff=$((current_time - last_run))

    if [[ $time_diff -lt 500 ]]; then
        # Too soon, let the dust settle
        sleep 0.5
    fi
fi

# Save current timestamp for debouncing
date +%s%3N > "$DEBOUNCEFILE"

# Try to acquire exclusive lock (non-blocking)
exec 200>"$LOCKFILE"
if ! flock -n 200; then
    # Another instance is running, exit silently
    exit 0
fi

# Wait for hardware to stabilize after profile change
sleep 0.2

# Get current profile
current_profile=$(asusctl profile --profile-get | grep "Active profile" | awk '{print $4}')

# Check if this is the same profile as last run (prevent feedback loop)
if [[ -f "$STATEFILE" ]]; then
    last_profile=$(cat "$STATEFILE")
    if [[ "$last_profile" == "$current_profile" ]]; then
        # Same profile, this is likely a feedback loop from tuned-adm
        exit 0
    fi
fi

# Save current profile to state file
echo "$current_profile" > "$STATEFILE"

# Map ASUS profiles to TuneD profiles
case "$current_profile" in
    "Quiet")
        /usr/sbin/tuned-adm profile powersave >/dev/null 2>&1
        /usr/bin/supergfxctl -m "Integrated" >/dev/null 2>&1
        icon="battery-profile-powersave"
        message="Profile: Quiet (Power Saver)"
        ;;
    "Balanced")
        /usr/sbin/tuned-adm profile balanced-battery >/dev/null 2>&1
        /usr/bin/supergfxctl -m "Hybrid" >/dev/null 2>&1
        icon="battery-060"
        message="Profile: Balanced"
        ;;
    "Performance")
        /usr/sbin/tuned-adm profile throughput-performance >/dev/null 2>&1
        /usr/bin/supergfxctl -m "Hybrid" >/dev/null 2>&1
        icon="battery-profile-performance"
        message="Profile: Performance"
        ;;
    *)
        icon="preferences-system-power-management"
        message="Profile: $current_profile"
        ;;
esac

# Show OSD toast notification
if command -v qdbus &> /dev/null; then
    qdbus org.kde.plasmashell /org/kde/osdService org.kde.osdService.showText "$icon" "$message" 2>/dev/null
elif command -v kwriteconfig5 &> /dev/null && command -v dbus-send &> /dev/null; then
    dbus-send --type=method_call --dest=org.kde.plasmashell /org/kde/osdService org.kde.osdService.showText string:"$icon" string:"$message" 2>/dev/null
elif command -v notify-send &> /dev/null; then
    notify-send -i "$icon" -t 2000 "ASUS Profile" "$message"
else
    echo "$message"
fi

exit 0
