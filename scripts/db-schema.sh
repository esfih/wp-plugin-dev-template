#!/usr/bin/env bash
# Inspect the live WordPress DB schema inside the local Docker runtime.
# Use this before designing new storage to avoid duplicate tables, missing indexes,
# or blob abuse. Answers the schema design gate questions in
# foundation/core/docs/IMPLEMENTATION-RULES.md — New Data Schema Design Gate.
#
# Usage:
#   ./scripts/db-schema.sh tables               List all tables in the WP database
#   ./scripts/db-schema.sh describe <table>     Full column/type/key definition
#   ./scripts/db-schema.sh sample <table> [N]   N sample rows (default: 5)
#   ./scripts/db-schema.sh indexes <table>      Show all indexes on a table
#   ./scripts/db-schema.sh search <pattern>     Find tables matching a name pattern
#
# Requires the local WordPress Docker stack to be running (docker compose up).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DB_SERVICE="db"
DB_NAME="${DB_NAME:-wordpress}"
DB_USER="${DB_USER:-wp_user}"
DB_PASS="${DB_PASSWORD:-wp_pass_dev}"

# Load .env overrides
if [[ -f "$REPO_ROOT/.env" ]]; then
  while IFS='=' read -r key value; do
    case "$key" in
      DB_NAME)     DB_NAME="$value" ;;
      DB_USER)     DB_USER="$value" ;;
      DB_PASSWORD) DB_PASS="$value" ;;
    esac
  done < <(grep -E '^(DB_NAME|DB_USER|DB_PASSWORD)=' "$REPO_ROOT/.env" || true)
fi

export MSYS_NO_PATHCONV=1

_db_query() {
  docker exec -i "$DB_SERVICE" mysql \
    -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" \
    --silent \
    -e "$1"
}

_require_table() {
  if [[ -z "${1:-}" ]]; then
    echo "Error: table name required." >&2
    exit 1
  fi
}

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: Docker CLI not found." >&2
  exit 2
fi

if [[ $# -eq 0 ]]; then
  cat <<'USAGE'
Usage: ./scripts/db-schema.sh <command> [args]

Commands:
  tables                  List all tables
  describe <table>        Show full column/type/key definition
  sample <table> [N]      Show N sample rows (default: 5)
  indexes <table>         Show all indexes on a table
  search <pattern>        Find tables matching a name pattern
USAGE
  exit 0
fi

COMMAND="$1"
shift

case "$COMMAND" in
  tables)
    _db_query "SHOW TABLES;"
    ;;
  describe)
    _require_table "${1:-}"
    _db_query "DESCRIBE \`${1}\`;"
    ;;
  sample)
    _require_table "${1:-}"
    N="${2:-5}"
    _db_query "SELECT * FROM \`${1}\` LIMIT ${N};"
    ;;
  indexes)
    _require_table "${1:-}"
    _db_query "SHOW INDEX FROM \`${1}\`;"
    ;;
  search)
    if [[ -z "${1:-}" ]]; then
      echo "Error: pattern required." >&2
      exit 1
    fi
    _db_query "SHOW TABLES LIKE '%${1}%';"
    ;;
  *)
    echo "Unknown command: $COMMAND" >&2
    echo "Run './scripts/db-schema.sh' for usage." >&2
    exit 2
    ;;
esac
