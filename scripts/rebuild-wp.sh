#!/usr/bin/env bash
# Rebuild the WordPress Docker service (e.g. after changing the Dockerfile or WP image).
# Stops, rebuilds, and restarts the wordpress container without losing DB data.
#
# Usage:
#   ./scripts/rebuild-wp.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: Docker CLI not found." >&2
  exit 2
fi

echo "==> Rebuilding WordPress service..."
docker compose build --no-cache wordpress
docker compose up -d wordpress
echo "Done. WordPress container rebuilt and started."
echo "Run './scripts/check-local-wp.sh' to verify."
