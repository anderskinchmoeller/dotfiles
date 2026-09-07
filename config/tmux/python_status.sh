#!/bin/bash
# Finds the first running python process and prints its elapsed time
result=$(ps -eo etime,cmd | grep '[p]ython' | head -1 | awk '{print $1}')
if [ -n "$result" ]; then
  echo "🐍 $result"
fi
