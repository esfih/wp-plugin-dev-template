#!/usr/bin/env bash
# bump-version.sh — atomically update the WordPress plugin Version: header and
# the WMOS_VERSION constant in the plugin bootstrap file.
#
# Usage:
#   scripts/bump-version.sh --plugin <slug> --to <version>
#
# Example:
#   scripts/bump-version.sh --plugin webmasteros --to 0.1.17
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/bump-version.sh --plugin <slug> --to <version>

Arguments:
  --plugin <slug>      Plugin slug (directory name under repo root, e.g. webmasteros)
  --to <version>       Target version string, e.g. 0.1.17
EOF
}

PLUGIN=""
VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plugin) PLUGIN="$2"; shift 2 ;;
    --to)     VERSION="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$PLUGIN" || -z "$VERSION" ]]; then
  usage
  exit 2
fi

bootstrap="${PLUGIN}/${PLUGIN}.php"

if [[ ! -f "$bootstrap" ]]; then
  echo "ERROR: plugin bootstrap not found: $bootstrap" >&2
  exit 1
fi

# Update the WordPress file-header Version: line (e.g. " * Version: 0.1.16")
sed -i "s/\( \* Version:\s*\)[0-9][0-9a-zA-Z._-]*/\1${VERSION}/" "$bootstrap"

# Update the WMOS_VERSION constant (handles optional spaces around the value)
sed -i "s/\(define(\s*'WMOS_VERSION'\s*,\s*'\)[^']*'/\1${VERSION}'/" "$bootstrap"

# Verify both changes landed
if ! grep -qE "Version:\s+${VERSION}" "$bootstrap"; then
  echo "ERROR: Version: header bump failed in $bootstrap" >&2
  exit 1
fi
if ! grep -qE "WMOS_VERSION.*${VERSION}" "$bootstrap"; then
  echo "ERROR: WMOS_VERSION constant bump failed in $bootstrap" >&2
  exit 1
fi

echo "Bumped $bootstrap to version ${VERSION}."
