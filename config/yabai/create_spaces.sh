#!/bin/sh
# Maintain six ordinary desktops; the sixth uses full-size stacked windows.
set -eu
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
spaces=$(yabai -m query --spaces)
count=$(printf '%s' "$spaces" | jq '[.[] | select(."is-native-fullscreen" == false)] | length')
while [ "$count" -lt 6 ]; do
    # Needs the scripting addition; stop trying instead of aborting the script.
    yabai -m space --create 1 || break
    count=$((count + 1))
done
# Evacuate surplus desktops before removing them, highest index first.
spaces=$(yabai -m query --spaces)
general=$(printf '%s' "$spaces" | jq -r '[.[] | select(."is-native-fullscreen" == false)][4].index')
extras=$(printf '%s' "$spaces" | jq -r '[.[] | select(."is-native-fullscreen" == false)][6:] | reverse | .[].index')
for index in $extras; do
    windows=$(yabai -m query --windows --space "$index" | jq -r '.[].id')
    for window in $windows; do
        yabai -m window "$window" --space "$general" || true
    done
    yabai -m space --destroy "$index" || true
done
spaces=$(yabai -m query --spaces)
slot=0
for label in claude brave signal sioyek general fullsize; do
    index=$(printf '%s' "$spaces" | jq -r --argjson slot "$slot" '[.[] | select(."is-native-fullscreen" == false)][$slot].index // empty')
    [ -n "$index" ] || break
    yabai -m space "$index" --label "$label" || true
    if [ "$label" = fullsize ]; then
        yabai -m config --space "$index" layout stack
        for padding in top_padding bottom_padding left_padding right_padding window_gap; do
            yabai -m config --space "$index" "$padding" 0
        done
    else
        yabai -m config --space "$index" layout bsp
    fi
    slot=$((slot + 1))
done
yabai -m rule --add label=route-claude app='^Claude$' space=claude
yabai -m rule --add label=route-brave app='^Brave Browser$' space=brave
yabai -m rule --add label=route-signal app='^Signal$' space=signal
yabai -m rule --add label=route-sioyek app='^[Ss]ioyek$' space=sioyek
# Rules route new windows; manual moves to space 6 remain in place.
if command -v sketchybar >/dev/null 2>&1; then
    sketchybar --trigger space_change --trigger windows_on_spaces || true
fi
