#!/usr/bin/env bash
# Sideload / internal-testing Android release APK.
# Usage (from repo root or downivo/):
#   bash downivo/scripts/build_release_apk.sh
#   bash scripts/build_release_apk.sh
# Options: --fat (all ABIs)  --aab  --open (reveal APK in Finder)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE="$ROOT/apps/mobile"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"

TARGET_PLATFORM="android-arm64"
BUILD_AAB=0
OPEN=0

usage() {
  cat <<'EOF'
Build a Downivo Android release APK for device testing.

  bash scripts/build_release_apk.sh [--fat] [--aab] [--open]

  --fat   Fat APK (arm, arm64, x64) instead of arm64-only
  --aab   Also build a Play Store app bundle
  --open  Reveal the APK in Finder (macOS)

Output:
  apps/mobile/build/app/outputs/flutter-apk/app-release.apk
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fat) TARGET_PLATFORM="" ;;
    --aab) BUILD_AAB=1 ;;
    --open) OPEN=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [[ ! -f "$MOBILE/pubspec.yaml" ]]; then
  echo "Mobile app not found at $MOBILE" >&2
  exit 1
fi

VERSION="$(awk '/^version:/ { print $2; exit }' "$MOBILE/pubspec.yaml")"
echo "==> Downivo $VERSION"
echo "==> GRADLE_USER_HOME=$GRADLE_USER_HOME"

cd "$MOBILE"
flutter pub get

if [[ -n "$TARGET_PLATFORM" ]]; then
  echo "==> flutter build apk --release --target-platform $TARGET_PLATFORM"
  flutter build apk --release --target-platform "$TARGET_PLATFORM"
else
  echo "==> flutter build apk --release"
  flutter build apk --release
fi

if [[ "$BUILD_AAB" -eq 1 ]]; then
  echo "==> flutter build appbundle --release"
  flutter build appbundle --release
fi

APK="$MOBILE/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$APK" ]]; then
  echo "APK was not produced at $APK" >&2
  exit 1
fi

echo ""
echo "Release APK: $APK"
ls -lh "$APK"

if [[ "$OPEN" -eq 1 ]] && command -v open >/dev/null 2>&1; then
  open -R "$APK"
fi
