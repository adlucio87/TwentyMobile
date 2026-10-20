#!/bin/bash
# ==============================================================================
# scripts/store/upload_binary.sh — Upload binario agli store (Internal Test / TestFlight)
#
# Uso:
#   scripts/store/upload_binary.sh [android|ios|all] [--track internal] [--status completed]
#   es.
#     scripts/store/upload_binary.sh android
#     scripts/store/upload_binary.sh ios
#     scripts/store/upload_binary.sh all
#
# Nessun submit per review pubblico automatico:
#   - Android: rilascia su Google Play traccia 'internal' (Internal Testing)
#   - iOS: carica la build su TestFlight
# ==============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
KIT="${STORE_KIT_DIR:-$ROOT_DIR/../store-kit}"
[ -x "$KIT/store" ] || { echo "❌ store-kit non trovato in $KIT"; exit 1; }

TARGET="${1:-android}"
shift || true

case "$TARGET" in
  android)
    exec python3 "$KIT/store" upload-binary --project "$ROOT_DIR" --android "$@"
    ;;
  ios)
    exec python3 "$KIT/store" upload-binary --project "$ROOT_DIR" --ios "$@"
    ;;
  all)
    exec python3 "$KIT/store" upload-binary --project "$ROOT_DIR" "$@"
    ;;
  *)
    exec python3 "$KIT/store" upload-binary --project "$ROOT_DIR" "$TARGET" "$@"
    ;;
esac
