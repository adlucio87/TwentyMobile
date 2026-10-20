#!/bin/bash
# ==============================================================================
# scripts/store/push.sh — Carica metadata e screenshots sugli store via Fastlane
#
# Uso: scripts/store/push.sh [--ios] [--android] [--dry-run] [--skip-screenshots]
# ==============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/store.sh" push "$@"
