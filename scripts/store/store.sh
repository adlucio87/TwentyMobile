#!/bin/bash
# ==============================================================================
# scripts/store/store.sh — wrapper su store-kit (metadata App Store / Google Play)
#
# Uso: scripts/store/store.sh <build|validate|pull|diff|import|push|upload-binary>
#                              [--ios] [--android] [--dry-run] [--force]
#                              [--skip-screenshots] [--aab PATH] [--ipa PATH]
#
# Credenziali: ~/.store-keys/ (fuori dal repo). Nessun submit automatico.
# ==============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
KIT="${STORE_KIT_DIR:-$ROOT_DIR/../store-kit}"
[ -x "$KIT/store" ] || { echo "❌ store-kit non trovato in $KIT"; exit 1; }
exec python3 "$KIT/store" "$1" --project "$ROOT_DIR" "${@:2}"
