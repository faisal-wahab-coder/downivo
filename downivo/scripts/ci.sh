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
  run "analyze ($pkg)" bash -c "cd '$ROOT/$pkg' && flutter analyze --no-fatal-infos"
done

for pkg in "${PACKAGES[@]}"; do
  if [[ -d "$ROOT/$pkg/test" ]]; then
    run "test ($pkg)" bash -c "cd '$ROOT/$pkg' && flutter test"
  fi
done

echo ""
echo "All CI checks passed."
