#!/bin/sh
# Called by yabai on window_resized. If the window just entered native macOS
# fullscreen (green button, menu item), undo it and zoom the window instead.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
id="${YABAI_WINDOW_ID:-}"
[ -n "$id" ] || exit 0
fs=$(yabai -m query --windows --window "$id" 2>/dev/null | jq -r '."is-native-fullscreen" // false')
[ "$fs" = true ] || exit 0

# One run per window at a time; resize events arrive in bursts.
lock="${TMPDIR:-/tmp}/yabai-no-fullscreen-$id"
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock"' EXIT

sleep 1.5   # let the fullscreen animation finish
yabai -m window "$id" --toggle native-fullscreen
sleep 1.5
yabai -m window "$id" --focus 2>/dev/null
zoomed=$(yabai -m query --windows --window "$id" 2>/dev/null | jq -r '."has-fullscreen-zoom" // false')
[ "$zoomed" = true ] || yabai -m window "$id" --toggle zoom-fullscreen
