#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${UD_WEB_PROXY_PORT:-8787}"
PROXY_URL="http://127.0.0.1:${PORT}"

cd "$ROOT"

if ! curl -sf "${PROXY_URL}/health" >/dev/null 2>&1; then
  echo "Starting web CORS proxy on ${PROXY_URL}"
  dart run tool/cors_proxy.dart &
  PROXY_PID=$!
  trap 'kill "$PROXY_PID" >/dev/null 2>&1 || true' EXIT
  for _ in $(seq 1 50); do
    if curl -sf "${PROXY_URL}/health" >/dev/null 2>&1; then
      break
    fi
    sleep 0.1
  done
  if ! curl -sf "${PROXY_URL}/health" >/dev/null 2>&1; then
    echo "Web CORS proxy failed to start on ${PROXY_URL}" >&2
    exit 1
  fi
else
  echo "Using existing web CORS proxy on ${PROXY_URL}"
  PROXY_PID=""
  trap - EXIT
fi

flutter run -d chrome --dart-define="UD_WEB_PROXY=${PROXY_URL}" "$@"
