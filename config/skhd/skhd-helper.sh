#!/usr/bin/env bash

set -u

readonly YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"
readonly JQ_BIN="${JQ_BIN:-/opt/homebrew/bin/jq}"

trigger_sketchybar() {
  if command -v sketchybar >/dev/null 2>&1; then
    sketchybar --trigger "$1" >/dev/null 2>&1 || true
  fi
}

window_json() {
  "$YABAI_BIN" -m query --windows --window 2>/dev/null
}

display_json() {
  if [[ -n "${1:-}" ]]; then
    "$YABAI_BIN" -m query --displays --display "$1" 2>/dev/null
  else
    "$YABAI_BIN" -m query --displays --display 2>/dev/null
  fi
}

space_for_slot() {
  local display="$1"
  local slot="$2"
  local index=$((slot - 1))

  display_json "$display" | "$JQ_BIN" -er ".spaces[$index] // empty" 2>/dev/null
}

focus_space() {
  local slot="$1"
  local target current

  target="$(space_for_slot "" "$slot")" || return 0
  current="$("$YABAI_BIN" -m query --spaces --space 2>/dev/null | "$JQ_BIN" -er '.index // empty' 2>/dev/null)" || return 0

  [[ "$target" == "$current" ]] || "$YABAI_BIN" -m space --focus "$target" >/dev/null 2>&1 || true
}

focus_direction() {
  local direction="$1"
  local edge

  if "$YABAI_BIN" -m window --focus "$direction" >/dev/null 2>&1; then
    return 0
  fi

  case "$direction" in
    west) edge='last' ;;
    east) edge='first' ;;
    north | south) edge='' ;;
    *) return 0 ;;
  esac

  if "$YABAI_BIN" -m display --focus "$direction" >/dev/null 2>&1; then
    [[ -z "$edge" ]] || "$YABAI_BIN" -m window --focus "$edge" >/dev/null 2>&1 || true
    return 0
  fi

  # Wrap horizontally when the focused window is already at the edge of the
  # current display. Vertical navigation remains directional-only.
  [[ -z "$edge" ]] || "$YABAI_BIN" -m window --focus "$edge" >/dev/null 2>&1 || true
}

move_direction() {
  local direction="$1"
  local window target_display delta

  window="$(window_json | "$JQ_BIN" -er '.id // empty' 2>/dev/null)" || return 0

  if "$YABAI_BIN" -m window "$window" --warp "$direction" >/dev/null 2>&1; then
    trigger_sketchybar windows_on_spaces
    return 0
  fi

  target_display="$(display_json "$direction" | "$JQ_BIN" -er '.index // empty' 2>/dev/null)" || target_display=""
  if [[ -n "$target_display" ]] &&
    "$YABAI_BIN" -m window "$window" --display "$target_display" >/dev/null 2>&1; then
    "$YABAI_BIN" -m display --focus "$target_display" >/dev/null 2>&1 || true
    trigger_sketchybar windows_on_spaces
    return 0
  fi

  case "$direction" in
    west)  delta='rel:-10:0' ;;
    east)  delta='rel:10:0'  ;;
    north) delta='rel:0:-10' ;;
    south) delta='rel:0:10'  ;;
    *) return 0 ;;
  esac

  "$YABAI_BIN" -m window "$window" --move "$delta" >/dev/null 2>&1 || true
}

move_to_space() {
  local slot="$1"
  local json window display current target fullscreen

  json="$(window_json)" || return 0
  window="$(printf '%s' "$json" | "$JQ_BIN" -er '.id // empty' 2>/dev/null)" || return 0
  display="$(printf '%s' "$json" | "$JQ_BIN" -er '.display // empty' 2>/dev/null)" || return 0
  current="$(printf '%s' "$json" | "$JQ_BIN" -er '.space // empty' 2>/dev/null)" || return 0
  target="$(space_for_slot "$display" "$slot")" || return 0

  [[ "$target" == "$current" ]] && return 0

  fullscreen="$(printf '%s' "$json" | "$JQ_BIN" -r '.["is-native-fullscreen"] // false' 2>/dev/null)"
  if [[ "$fullscreen" == 'true' ]]; then
    "$YABAI_BIN" -m window "$window" --toggle native-fullscreen >/dev/null 2>&1 || return 0
    sleep 1
  fi

  if "$YABAI_BIN" -m window "$window" --space "$target" >/dev/null 2>&1; then
    trigger_sketchybar windows_on_spaces
  fi
}

toggle_sketchybar_margin() {
  local current

  command -v sketchybar >/dev/null 2>&1 || return 0
  current="$(sketchybar --query bar 2>/dev/null | "$JQ_BIN" -er '.y_offset' 2>/dev/null)" || return 0

  if [[ "$current" == '0' ]]; then
    "$YABAI_BIN" -m config external_bar all:49:0 >/dev/null 2>&1 || true
    sketchybar --animate sin 15 --bar margin=10 y_offset=10 corner_radius=9 >/dev/null 2>&1
  else
    "$YABAI_BIN" -m config external_bar all:39:0 >/dev/null 2>&1 || true
    sketchybar --animate sin 15 --bar margin=0 y_offset=0 corner_radius=0 >/dev/null 2>&1
  fi
}

toggle_borders() {
  local borders_bin
  borders_bin="$(command -v borders 2>/dev/null || echo /opt/homebrew/bin/borders)"

  if pgrep -x borders >/dev/null 2>&1; then
    pkill -x borders >/dev/null 2>&1 || true
  elif [[ -x "$borders_bin" ]]; then
    # Same style as yabairc starts at login.
    "$borders_bin" active_color=0xff58a6ff inactive_color=0xff58a6ff width=5.0 >/dev/null 2>&1 &
    disown 2>/dev/null || true
  fi
}

case "${1:-}" in
  focus-space)        focus_space "${2:-0}" ;;
  focus-direction)    focus_direction "${2:-}" ;;
  move-direction)     move_direction "${2:-}" ;;
  move-to-space)      move_to_space "${2:-0}" ;;
  toggle-bar-margin)  toggle_sketchybar_margin ;;
  toggle-borders)     toggle_borders ;;
esac
