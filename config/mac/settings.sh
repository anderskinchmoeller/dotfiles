#!/usr/bin/env bash

# Backwards-compatible entry point. Keep all macOS preferences in defaults.sh.
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/defaults.sh" "$@"
