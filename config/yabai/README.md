# Automatic yabai tiling

Active copies live in `~/.config/yabai/`; this directory stores the repository copy.

- Desktops 1–5 use `bsp` for automatic tiling.
- Desktop 6 (`fullsize`) uses `stack` with no padding.
- Cmd+6 focuses desktop 6; Shift+Cmd+6 sends a window there.
- App rules route new Claude, Brave Browser, Signal and Sioyek windows to their labelled desktops.
- System Settings and Spotify float; Ghostty is explicitly managed and tiles.
- Minimising is undone immediately (`no-minimize` signal); Cmd+M is bound to Kitty in skhd anyway.
- Native macOS fullscreen is replaced by zoom-fullscreen: `no-native-fullscreen.sh` runs on `window_resized`, leaves native fullscreen again and zooms the window instead. The green button therefore enlarges the window within its Space (after a short animation). Ctrl+Cmd+F and Fn+F are bound to zoom-fullscreen in skhd.

Both `yabairc` and `create_spaces.sh` select tiling, so configuration reloads and login keep the same layout policy. The manual-layout worker is no longer started: restoring saved freeform window positions conflicts with automatic tiling. Its script and private snapshots in `~/.local/state/yabai-layouts/` are retained for optional future use.

`create_spaces.sh` maintains six ordinary desktops and evacuates surplus desktops to desktop 5 before removing them. Space creation and movement require the yabai scripting addition; window resizing requires Accessibility permission.
