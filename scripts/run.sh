#!/usr/bin/env bash
# Unified runner for repository tooling.
# Validates prerequisites then dispatches to scripts/*.
#
# Usage:
#   ./scripts/run.sh <tool> [args...]
#
# Examples:
#   ./scripts/run.sh wp wp plugin list
#   ./scripts/run.sh check-local-wp
#   ./scripts/run.sh db-schema tables

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/.."
cd "$repo_root"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <tool> [args...]"
  echo ""
  echo "Available tools:"
  ls scripts/ | grep -v '^_' | grep -E '\.(sh|py)$|^[^.]+$' | sort
  exit 1
fi

tool="$1"
shift

if [[ "$tool" =~ ^(help|-h|--help)$ ]]; then
  echo "Available tools in scripts/:"
  ls scripts/ | grep -v '^_' | sort
  exit 0
fi

# Validate prerequisites before running tool commands.
./scripts/check-prereqs.sh

if [ -x "./scripts/$tool" ] || [ -x "./scripts/${tool}.sh" ]; then
  exec "./scripts/${tool}${tool##*.sh}" "$@" 2>/dev/null \
    || exec "./scripts/$tool" "$@"
else
  echo "Unknown tool: $tool" >&2
  echo "Run '$0 help' to list available tools." >&2
  exit 2
fi
