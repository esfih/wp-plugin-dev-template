#!/usr/bin/env bash
set -euo pipefail

CORE_REMOTE="${CORE_REMOTE:-master-core}"
WP_REMOTE="${WP_REMOTE:-wp-overlay}"
BRANCH="${FOUNDATION_BRANCH:-main}"

git fetch "$CORE_REMOTE" "$BRANCH"
git fetch "$WP_REMOTE" "$BRANCH"
git subtree pull --prefix foundation/core "$CORE_REMOTE" "$BRANCH" --squash
git subtree pull --prefix foundation/wp "$WP_REMOTE" "$BRANCH" --squash