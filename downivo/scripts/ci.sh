#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PACKAGES=(
  packages/shared_types
  packages/shared_utils
  packages/design_system
  packages/navigation
  packages/database
  packages/storage
  packages/permissions
  packages/performance
  packages/download_engine
  packages/job_manager
  packages/notifications
  packages/browser
  packages/content_intake
  packages/media_library
  packages/search
  packages/universal_viewer
  packages/analytics
  packages/app_core
  apps/mobile
  apps/web
)

run() {
  local label="$1"
  shift
  echo ""
  echo "==> $label"
  "$@"
}

for pkg in "${PACKAGES[@]}"; do
  run "pub get ($pkg)" bash -c "cd '$ROOT/$pkg' && flutter pub get"
done

for pkg in "${PACKAGES[@]}"; do
  # Infos and existing warnings must not fail public CI. Tightening
  # --no-fatal-warnings is a follow-up once download_engine is clean.
  run "analyze ($pkg)" bash -c "cd '$ROOT/$pkg' && flutter analyze --no-fatal-infos --no-fatal-warnings"
done

for pkg in "${PACKAGES[@]}"; do
  if [[ -d "$ROOT/$pkg/test" ]]; then
    run "test ($pkg)" bash -c "cd '$ROOT/$pkg' && flutter test"
  fi
done

echo ""
echo "All CI checks passed."
