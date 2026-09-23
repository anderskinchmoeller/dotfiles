#!/bin/bash
# Report whether every path in install.conf.yaml's link section is a symlink
# into this repository. Read-only: changes nothing.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
bad=0
while IFS= read -r line; do
  dst="${line%%:*}"; src="${line#*: }"
  dst="${dst/#\~/$HOME}"; want="$REPO/$src"
  if [ -L "$dst" ]; then
    got="$(readlink "$dst")"
    if [ "$got" = "$want" ]; then printf 'OK       %s\n' "$dst"
    else printf 'WRONG    %s -> %s (expected %s)\n' "$dst" "$got" "$want"; bad=1; fi
  elif [ -d "$dst" ]; then printf 'FOLDER   %s (real folder, not linked)\n' "$dst"; bad=1
  elif [ -e "$dst" ]; then printf 'FILE     %s (real file, not linked)\n' "$dst"; bad=1
  else printf 'MISSING  %s\n' "$dst"; bad=1; fi
done < <(sed -n '/^- link:/,/^- /{s/^    \(~[^:]*\): *\(.*\)$/\1: \2/p;}' "$REPO/install.conf.yaml")
exit $bad
