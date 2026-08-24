#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_DIR="$ROOT/qa/reports"
STAMP="$(date +%Y%m%d_%H%M%S)"
REPORT="$REPORT_DIR/qa_${STAMP}.txt"
SUITE="${1:-all}"

mkdir -p "$REPORT_DIR"

log() {
  echo "$@" | tee -a "$REPORT"
}

run_pkg_tests() {
  local pkg="$1"
  shift
  log ""
  log "==> $pkg $*"
  (
    cd "$ROOT/$pkg"
    flutter test "$@"
  ) 2>&1 | tee -a "$REPORT"
}

case "$SUITE" in
  all|regression)
    log "Master regression $STAMP"
    (cd "$ROOT/qa/server" && dart pub get) >/dev/null
    run_pkg_tests packages/download_engine
    run_pkg_tests packages/storage
    run_pkg_tests packages/database
    run_pkg_tests packages/media_library
    run_pkg_tests packages/browser
    run_pkg_tests packages/content_intake
    run_pkg_tests packages/notifications
    run_pkg_tests packages/permissions
    run_pkg_tests packages/performance
    run_pkg_tests packages/job_manager
    run_pkg_tests packages/shared_utils
    run_pkg_tests packages/app_core
    run_pkg_tests apps/mobile
    ;;
  download)
    (cd "$ROOT/qa/server" && dart pub get) >/dev/null
    run_pkg_tests packages/download_engine
    ;;
  storage) run_pkg_tests packages/storage ;;
  database) run_pkg_tests packages/database ;;
  files|library) run_pkg_tests packages/media_library ;;
  browser) run_pkg_tests packages/browser ;;
  intake) run_pkg_tests packages/content_intake ;;
  notifications) run_pkg_tests packages/notifications ;;
  permissions) run_pkg_tests packages/permissions ;;
  security)
    (cd "$ROOT/qa/server" && dart pub get) >/dev/null
    run_pkg_tests packages/download_engine test/security_test.dart
    ;;
  performance) run_pkg_tests packages/performance ;;
  recovery)
    run_pkg_tests packages/download_engine test/integration/crash_recovery_test.dart
    ;;
  *)
    echo "Unknown suite: $SUITE" >&2
    echo "Suites: all, regression, download, storage, database, files, browser, intake, notifications, permissions, security, performance, recovery" >&2
    exit 2
    ;;
esac

log ""
log "QA suite '$SUITE' passed. Report: $REPORT"
