#!/bin/bash

sleep 0.3

# Get current profile
current_profile=$(asusctl profile --profile-get | grep "Active profile" | awk '{print $4}')

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
