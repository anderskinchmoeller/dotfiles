#!/bin/bash
# Upgrade yabai and refresh the sudoers rule that lets yabairc load the
# scripting addition without a password. The rule pins yabai's SHA-256, so it
# must be rewritten after every upgrade. yabai is kept pinned in Homebrew so a
# plain `brew upgrade` never breaks it; use this script instead.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

brew unpin yabai >/dev/null 2>&1 || true
brew upgrade yabai || true          # "already up-to-date" is fine
brew pin yabai

YABAI="$(command -v yabai)"
HASH="$(shasum -a 256 "$YABAI" | cut -d ' ' -f 1)"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
printf '%s ALL=(root) NOPASSWD: sha256:%s %s --load-sa\n' "$(whoami)" "$HASH" "$YABAI" > "$TMP"

sudo visudo -cf "$TMP"              # refuse to install a broken rule
sudo install -m 0440 -o root -g wheel "$TMP" /private/etc/sudoers.d/yabai

yabai --restart-service
sleep 2
if sudo -n "$YABAI" --load-sa; then
  echo "yabai $(yabai --version): scripting addition loaded, sudoers rule updated."
else
  echo "Scripting addition failed to load. Check SIP (csrutil status) and yabai's wiki." >&2
  exit 1
fi
