#!/usr/bin/env bash
# Verify the docker-compose wiring is in standard two-plugin mode.
# Ensures no accidental public-plugins mounts that would break deterministic testing.
#
# Usage:
#   ./scripts/check-two-plugin-compose.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker CLI not found. Cannot validate compose plugin mounts." >&2
  exit 2
fi

compose_config="$(docker compose config 2>/dev/null || true)"
if [[ -z "$compose_config" ]]; then
  echo "Failed to read docker compose config. Is Docker running?" >&2
  exit 2
fi

# Read plugin slugs from .env if present
PLUGIN_SLUG="${PLUGIN_SLUG:-}"
CP_PLUGIN_SLUG="${CP_PLUGIN_SLUG:-}"
if [[ -f "$REPO_ROOT/.env" ]]; then
  while IFS='=' read -r key value; do
    case "$key" in
      PLUGIN_SLUG)     PLUGIN_SLUG="$value" ;;
      CP_PLUGIN_SLUG)  CP_PLUGIN_SLUG="$value" ;;
    esac
  done < <(grep -E '^(PLUGIN_SLUG|CP_PLUGIN_SLUG)=' "$REPO_ROOT/.env" || true)
fi

FAIL=0

# Warn if any unexpected public-plugins or third-party mount points are present
if grep -q "public-plugins/" <<<"$compose_config"; then
  echo "FAIL: docker compose config references public-plugins/ mounts. Remove them to keep two-plugin mode deterministic." >&2
  FAIL=1
fi

# Confirm expected plugin mounts are present
if [[ -n "$PLUGIN_SLUG" ]]; then
  if grep -q "$PLUGIN_SLUG" <<<"$compose_config"; then
    echo "OK: app plugin mount ($PLUGIN_SLUG) found in compose config."
  else
    echo "WARN: no mount for $PLUGIN_SLUG found in compose config." >&2
  fi
fi

if [[ -n "$CP_PLUGIN_SLUG" ]]; then
  if grep -q "$CP_PLUGIN_SLUG" <<<"$compose_config"; then
    echo "OK: control-plane plugin mount ($CP_PLUGIN_SLUG) found in compose config."
  else
    echo "WARN: no mount for $CP_PLUGIN_SLUG found in compose config." >&2
  fi
fi

if [[ $FAIL -eq 1 ]]; then
  exit 1
fi

echo "OK: docker compose is in two-plugin mode."
