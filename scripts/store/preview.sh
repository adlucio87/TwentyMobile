#!/bin/bash
# ==============================================================================
# scripts/store/preview.sh — Genera e apre la pagina HTML di anteprima dello store
#
# Uso: scripts/store/preview.sh [--lang it-IT|en-US|...] [--no-open]
# ==============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/store.sh" preview "$@"
