#!/bin/sh

pane=${1#%}
started=$(tmux show-option -gqv "@command_started_$pane")

case $started in
  ''|*[!0-9]*) exit 0 ;;
esac

elapsed=$(($(date +%s) - started))
hours=$((elapsed / 3600))
minutes=$(((elapsed % 3600) / 60))
seconds=$((elapsed % 60))

if [ "$hours" -gt 0 ]; then
  printf '⏱ %dh %02dm %02ds' "$hours" "$minutes" "$seconds"
elif [ "$minutes" -gt 0 ]; then
  printf '⏱ %dm %02ds' "$minutes" "$seconds"
else
  printf '⏱ %ds' "$seconds"
fi
