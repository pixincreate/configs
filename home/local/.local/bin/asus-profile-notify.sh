#!/bin/bash

# Shows OSD toast when power profile changes via Fn+F5

# Get current profile from asusctl
current_profile=$(asusctl profile --profile-get 2>/dev/null | grep "Active profile" | awk '{print $4}')

# Map ASUS profiles to icons and messages
case "$current_profile" in
    "Quiet")
        icon="battery-profile-powersave"
        message="Profile: Quiet (Power Saver)"
        ;;
    "Balanced")
        icon="battery-060"
        message="Profile: Balanced"
        ;;
    "Performance")
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
