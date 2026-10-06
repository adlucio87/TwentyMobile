#!/bin/bash
# ==============================================================================
# scripts/verify/flutter.sh
# Analisi statica (flutter analyze) + test (flutter test) del progetto Flutter.
#
# Rileva automaticamente la directory dell'app: root del repo oppure ./app.
# Salta senza errore se il progetto non è Flutter (nessun pubspec.yaml).
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- Rileva la directory dell'app Flutter (dove sta pubspec.yaml) ---
if [ -f "$ROOT_DIR/pubspec.yaml" ]; then
    APP_DIR="$ROOT_DIR"
elif [ -f "$ROOT_DIR/app/pubspec.yaml" ]; then
    APP_DIR="$ROOT_DIR/app"
else
    echo "=== Flutter ==="
    echo "⏭️  Nessun pubspec.yaml in '$ROOT_DIR' né in '$ROOT_DIR/app' — skip."
    exit 0
fi

echo "=== Flutter ==="
echo "📂 App dir: $APP_DIR"
cd "$APP_DIR"

flutter pub get
flutter analyze
flutter test

echo "=== FLUTTER VERIFY OK ==="
