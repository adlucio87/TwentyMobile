#!/usr/bin/env bash
set -e

# PocketCRM / TwentyMobile Build Script for Android & iOS
# Usage:
#   ./scripts/deploy/app.sh [all|android|ios] [--bump patch|minor|build|none] [--version X.Y.Z+BUILD]

TARGET="all"
BUMP_MODE="patch" # default: bump patch and build number (e.g. 1.0.16+42 -> 1.0.17+43)
CUSTOM_VERSION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        all|android|ios)
            TARGET="$1"
            shift
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --bump)
            BUMP_MODE="$2"
            shift 2
            ;;
        --no-bump)
            BUMP_MODE="none"
            shift
            ;;
        --version)
            CUSTOM_VERSION="$2"
            BUMP_MODE="custom"
            shift 2
            ;;
        *)
            echo "❌ Parametro sconosciuto: $1"
            echo "Uso: $0 [all|android|ios] [--bump patch|minor|build|none] [--version X.Y.Z+BUILD]"
            exit 1
            ;;
    esac
done

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

# Extract current version from pubspec.yaml
CURRENT_VERSION=$(grep -E '^version:\s*' pubspec.yaml | awk '{print $2}')

bump_version() {
    if [[ "$BUMP_MODE" == "none" ]]; then
        NEW_VERSION="$CURRENT_VERSION"
        echo "ℹ️  Nessun incremento di versione richiesto. Versione corrente: $NEW_VERSION"
        return
    fi

    if [[ "$BUMP_MODE" == "custom" ]]; then
        NEW_VERSION="$CUSTOM_VERSION"
    else
        # Match X.Y.Z+BUILD
        if [[ "$CURRENT_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)$ ]]; then
            MAJOR="${BASH_REMATCH[1]}"
            MINOR="${BASH_REMATCH[2]}"
            PATCH="${BASH_REMATCH[3]}"
            BUILD="${BASH_REMATCH[4]}"
            NEXT_BUILD=$((BUILD + 1))

            case "$BUMP_MODE" in
                patch)
                    NEXT_PATCH=$((PATCH + 1))
                    NEW_VERSION="${MAJOR}.${MINOR}.${NEXT_PATCH}+${NEXT_BUILD}"
                    ;;
                minor)
                    NEXT_MINOR=$((MINOR + 1))
                    NEW_VERSION="${MAJOR}.${NEXT_MINOR}.0+${NEXT_BUILD}"
                    ;;
                build)
                    NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}+${NEXT_BUILD}"
                    ;;
                *)
                    echo "❌ Modalità bump sconosciuta: $BUMP_MODE"
                    exit 1
                    ;;
            esac
        else
            echo "❌ Impossibile interpretare la versione corrente in pubspec.yaml: '$CURRENT_VERSION'"
            exit 1
        fi
    fi

    if [[ "$NEW_VERSION" != "$CURRENT_VERSION" ]]; then
        echo "🆙 Incremento versione in pubspec.yaml: $CURRENT_VERSION ➔ $NEW_VERSION"
        sed -i '' -E "s/^version:[[:space:]]+.*$/version: ${NEW_VERSION}/" pubspec.yaml
    else
        echo "ℹ️  Versione invariata: $NEW_VERSION"
    fi
}

bump_version

echo ""
echo "=========================================="
echo "🚀 TwentyMobile - Build Release"
echo "Versione: $NEW_VERSION"
echo "Target:   $TARGET"
echo "Directory: $PROJECT_ROOT"
echo "=========================================="

echo "🌐 Generazione localizzazioni (flutter gen-l10n)..."
flutter gen-l10n

echo "📦 Risoluzione dipendenze (flutter pub get)..."
flutter pub get

build_android() {
    echo ""
    echo "=========================================="
    echo "🤖 Compilazione Android Release"
    echo "=========================================="
    
    echo "▶ Compilazione AppBundle (.aab)..."
    flutter build appbundle --release
    echo "✅ AppBundle generato con successo: build/app/outputs/bundle/release/app-release.aab"
    
    echo "▶ Compilazione APK (.apk)..."
    flutter build apk --release
    echo "✅ APK generato con successo: build/app/outputs/flutter-apk/app-release.apk"
}

build_ios() {
    echo ""
    echo "=========================================="
    echo "🍎 Compilazione iOS Release"
    echo "=========================================="
    
    echo "▶ Verifica CocoaPods (ios/Podfile)..."
    (cd ios && pod install)
    
    echo "▶ Compilazione iOS Release Archive & IPA..."
    if flutter build ipa --release; then
        echo "✅ IPA generato con successo: build/ios/ipa/TwentyMobile.ipa"
    else
        echo "⚠️  'flutter build ipa' richiede un profilo di provisioning di distribuzione App Store configurato in Xcode."
        echo "▶ Compilazione archivio release (senza codesign manuale)..."
        flutter build ios --release --no-codesign
        echo "✅ iOS Release Archive generato con successo in build/ios/iphoneos/Runner.app"
    fi
}

case "$TARGET" in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    all)
        build_android
        build_ios
        ;;
esac

echo ""
echo "=========================================="
echo "🎉 Build $NEW_VERSION completata con successo!"
echo "=========================================="
