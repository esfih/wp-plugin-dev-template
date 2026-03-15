#!/usr/bin/env bash
set -euo pipefail

CORE_REMOTE_NAME="${CORE_REMOTE_NAME:-master-core}"
WP_REMOTE_NAME="${WP_REMOTE_NAME:-wp-overlay}"
CORE_REMOTE_URL="${CORE_REMOTE_URL:-}"
WP_REMOTE_URL="${WP_REMOTE_URL:-}"
BRANCH="${FOUNDATION_BRANCH:-main}"

add_or_update_remote() {
  local name="$1"
  local url="$2"
  if [[ -z "$url" ]]; then
    return 0
  fi

  if git remote get-url "$name" >/dev/null 2>&1; then
    git remote set-url "$name" "$url"
  else
    git remote add "$name" "$url"
  fi
}

pull_subtree() {
  local prefix="$1"
  local remote="$2"
  git fetch "$remote" "$BRANCH"
  git subtree add --prefix "$prefix" "$remote" "$BRANCH" --squash
}

add_or_update_remote "$CORE_REMOTE_NAME" "$CORE_REMOTE_URL"
add_or_update_remote "$WP_REMOTE_NAME" "$WP_REMOTE_URL"

if [[ ! -d foundation/core ]]; then
  pull_subtree foundation/core "$CORE_REMOTE_NAME"
fi

if [[ ! -d foundation/wp ]]; then
  pull_subtree foundation/wp "$WP_REMOTE_NAME"
fi

echo "Foundation bootstrap complete."