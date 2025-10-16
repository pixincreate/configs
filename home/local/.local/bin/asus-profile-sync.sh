#!/bin/bash
# Listen to asusd D-Bus signals and sync tuned profile
# This replaces the udev-based approach to avoid feedback loops

# Profile mapping (from busctl output: 0=Performance, 1=Balanced, 2=Quiet, 3=?)
get_profile_name() {
    case "$1" in
        0) echo "Performance" ;;
        1) echo "Balanced" ;;
        2) echo "Quiet" ;;
        *) echo "Unknown" ;;
    esac
}

# Map profile to tuned and show notification
apply_profile() {
    local profile_num="$1"
    local profile_name=$(get_profile_name "$profile_num")

    case "$profile_name" in
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
            message="Profile: $profile_name"
            ;;
    esac

    # Show notification
    if command -v qdbus >/dev/null 2>&1; then
        qdbus org.kde.plasmashell /org/kde/osdService org.kde.osdService.showText "$icon" "$message" 2>/dev/null
    elif command -v notify-send >/dev/null 2>&1; then
        notify-send -i "$icon" -t 2000 "ASUS Profile" "$message" 2>/dev/null
    fi
}

# Monitor D-Bus for PlatformProfile changes
dbus-monitor --system "type='signal',sender='xyz.ljones.Asusd',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/xyz/ljones'" | \
while read -r line; do
    # Look for PlatformProfile property changes
    if echo "$line" | grep -q "PlatformProfile"; then
        # Next line should contain the new value
        read -r value_line
        if echo "$value_line" | grep -q "uint32"; then
            profile_num=$(echo "$value_line" | grep -oP 'uint32 \K\d+')
            apply_profile "$profile_num"
        fi
    fi
done
