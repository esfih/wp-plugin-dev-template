#!/usr/bin/env bash
# Check that the local WordPress Docker stack is healthy and both plugins are active.
# Reads WP_SERVICE from .env if present. Checks:
#   - docker compose services are running
#   - WordPress site is reachable on the expected port
#   - Both app plugin and control-plane plugin are active
#
# Usage:
#   ./scripts/check-local-wp.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

WP_SERVICE="wordpress"
WP_PORT="8080"
PLUGIN_SLUG=""
CP_PLUGIN_SLUG=""

if [[ -f "$ENV_FILE" ]]; then
  while IFS='=' read -r key value; do
    case "$key" in
      WP_PORT)         WP_PORT="$value" ;;
      PLUGIN_SLUG)     PLUGIN_SLUG="$value" ;;
      CP_PLUGIN_SLUG)  CP_PLUGIN_SLUG="$value" ;;
    esac
  done < <(grep -E '^(WP_PORT|PLUGIN_SLUG|CP_PLUGIN_SLUG)=' "$ENV_FILE" || true)
fi

export MSYS_NO_PATHCONV=1

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker CLI not found." >&2
  exit 2
fi

echo "==> Checking Docker services..."
if ! docker compose -f "$REPO_ROOT/docker-compose.yml" ps --status running --services 2>/dev/null | grep -qx "$WP_SERVICE"; then
  echo "FAIL: '$WP_SERVICE' service is not running. Run: docker compose up -d" >&2
  exit 1
fi
echo "OK: $WP_SERVICE is running."

echo "==> Checking WordPress HTTP response (port $WP_PORT)..."
status="$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:${WP_PORT}/" || true)"
if [[ "$status" != "200" && "$status" != "301" && "$status" != "302" ]]; then
  echo "WARN: http://localhost:${WP_PORT}/ returned HTTP $status (expected 200/301/302)." >&2
else
  echo "OK: WordPress responds on port $WP_PORT (HTTP $status)."
fi

echo "==> Checking WP-CLI is available..."
if ! docker exec -i "$WP_SERVICE" wp --info --allow-root >/dev/null 2>&1; then
  echo "WARN: WP-CLI not available in container." >&2
else
  echo "OK: WP-CLI available."
fi

echo "==> Checking plugin status..."
if [[ -n "$PLUGIN_SLUG" ]]; then
  if docker exec -i "$WP_SERVICE" wp plugin is-active "$PLUGIN_SLUG" --allow-root >/dev/null 2>&1; then
    echo "OK: $PLUGIN_SLUG is active."
  else
    echo "WARN: $PLUGIN_SLUG is not active. Run: ./scripts/wp.sh wp plugin activate $PLUGIN_SLUG"
  fi
fi

if [[ -n "$CP_PLUGIN_SLUG" ]]; then
  if docker exec -i "$WP_SERVICE" wp plugin is-active "$CP_PLUGIN_SLUG" --allow-root >/dev/null 2>&1; then
    echo "OK: $CP_PLUGIN_SLUG is active."
  else
    echo "WARN: $CP_PLUGIN_SLUG is not active. Run: ./scripts/wp.sh wp plugin activate $CP_PLUGIN_SLUG"
  fi
fi

echo ""
echo "Check complete. Resolve any FAIL/WARN items above before starting feature work."
