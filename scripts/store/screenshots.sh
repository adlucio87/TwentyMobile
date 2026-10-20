#!/bin/bash
# ==============================================================================
# scripts/store/screenshots.sh — Genera mockup e grafiche multilingua per TwentyMobile
# ==============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/generate_mockups.py" "$@"
