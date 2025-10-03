#!/bin/bash

sleep 0.1

# Get current profile
current_profile=$(asusctl profile --profile-get | grep "Active profile" | awk '{print $4}')

# Sync with tuned and supergfxctl based on profile
case "$current_profile" in
    "Quiet")
        # Power saving mode
        tuned-adm profile powersave 2>/dev/null
        supergfxctl -m integrated 2>/dev/null
        icon="battery-profile-powersave"
        message="Profile: Quiet (Power Saver)"
        ;;
    "Balanced")
        # Balanced mode
        tuned-adm profile balanced-battery 2>/dev/null
        supergfxctl -m hybrid 2>/dev/null
        icon="battery-060"
        message="Profile: Balanced"
        ;;
    "Performance")
        # Performance mode
        tuned-adm profile throughput-performance 2>/dev/null
        supergfxctl -m hybrid 2>/dev/null
        icon="battery-profile-performance"
        message="Profile: Performance"
        ;;
    *)
        icon="preferences-system-power-management"
        message="Profile: $current_profile"
        ;;
esac

# Show OSD toast notification (KDE system-style)
if command -v qdbus &> /dev/null; then
    # Use KDE's OSD system (like volume/brightness toasts)
    qdbus org.kde.plasmashell /org/kde/osdService org.kde.osdService.showText "$icon" "$message" 2>/dev/null &
elif command -v kwriteconfig5 &> /dev/null && command -v dbus-send &> /dev/null; then
    # Alternative method using dbus-send
    dbus-send --type=method_call --dest=org.kde.plasmashell /org/kde/osdService org.kde.osdService.showText string:"$icon" string:"$message" 2>/dev/null &
elif command -v notify-send &> /dev/null; then
    # Fallback to regular notification
    notify-send -i "$icon" -t 2000 "ASUS Profile" "$message"
else
    # Terminal fallback
    echo "$message"
fi

exit 0
