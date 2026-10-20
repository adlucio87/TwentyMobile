#!/bin/bash
# ==============================================================================
# scripts/store/pull.sh — Scarica metadata attuali dagli store in store/.pulled/
#
# Uso: scripts/store/pull.sh [--ios] [--android]
# ==============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/store.sh" pull "$@"
