#!/bin/bash
# Turn every unlinked path from install.conf.yaml into a symlink into this repo.
#
#   scripts/adopt-links.sh           dry run: show what differs, change nothing
#   scripts/adopt-links.sh --apply   do it
#
# For each path that is a real file/folder, --apply:
#   1. copies the live version of files the repo already has over the repo copy
#      (the live one is what you actually use). Files that exist only in the
#      live folder (scratch files, nested .git, backups) are NOT copied; they
#      stay in the .pre-dotbot folder. Exception: SketchyBar's compiled helper.
#   2. moves the live path aside to <path>.pre-dotbot-<timestamp>;
#   3. creates the symlink.
# Review the result with `git diff` / `git status`; `git checkout -- <file>`
# restores the previous repo version if the live one was worse.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
APPLY=0; [ "${1:-}" = "--apply" ] && APPLY=1
TS="$(date +%Y%m%d-%H%M%S)"
EXCL=(--exclude .git --exclude .DS_Store --exclude node_modules --exclude automatic_backups
      --exclude '*.bak' --exclude '*.backup*' --exclude '*.pre-*' --exclude '*.before-*'
      --exclude 'backup*' --exclude '*.swp' --exclude '*.zwc' --exclude __pycache__)

while IFS= read -r line; do
  dst="${line%%:*}"; src="${line#*: }"
  dst="${dst/#\~/$HOME}"; want="$REPO/$src"
  if [ -L "$dst" ]; then continue; fi
  if [ ! -e "$dst" ]; then
    echo "MISSING  $dst"
    [ $APPLY = 1 ] && mkdir -p "$(dirname "$dst")" && ln -s "$want" "$dst" && echo "  linked"
    continue
  fi
  if [ -d "$dst" ]; then
    changes=$(rsync -rcnv "${EXCL[@]}" "$dst/" "$want/" 2>/dev/null \
      | grep -Ev '/$|^$|^(sending|sent|total size|building|Transfer starting|created directory|receiving)|files to consider|speedup is')
  else
    changes=$(cmp -s "$dst" "$want" || echo "$(basename "$dst")")
  fi
  if [ -z "$changes" ]; then echo "SAME     $dst"
  else
    echo "DIFFERS  $dst"
    while IFS= read -r f; do
      if [ -d "$dst" ] && [ ! -e "$want/$f" ]; then echo "           only live, stays in backup: $f"
      else echo "           changed, live copied to repo: $f"; fi
    done <<< "$changes"
  fi

  [ $APPLY = 1 ] || continue
  if [ -d "$dst" ]; then
    rsync -a --existing "${EXCL[@]}" "$dst/" "$want/"
    [ -x "$dst/helper/helper" ] && [ "$src" = config/sketchybar ] && cp -p "$dst/helper/helper" "$want/helper/helper"
  else cp -p "$dst" "$want"; fi
  mv "$dst" "$dst.pre-dotbot-$TS" && ln -s "$want" "$dst" && echo "  -> linked (old kept as $dst.pre-dotbot-$TS)"
done < <(sed -n '/^- link:/,/^- /{s/^    \(~[^:]*\): *\(.*\)$/\1: \2/p;}' "$REPO/install.conf.yaml")

[ $APPLY = 1 ] || echo; [ $APPLY = 1 ] || echo "Dry run only. Run with --apply to link."
