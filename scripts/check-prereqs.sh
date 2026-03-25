#!/usr/bin/env bash
# Verify prerequisites for repository tooling and provide actionable install hints.
# Run this after cloning to confirm all required tools are present.
# See WORKSPACE-SETUP.md for full setup guide.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/.."
cd "$repo_root"

missing=0
recommended_missing=0

check_cmd_required() {
  local cmd="$1"
  local hint="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf "[MISSING] %s\n" "$cmd"
    [ -n "$hint" ] && printf "        %s\n" "$hint"
    missing=1
  fi
}

check_cmd_recommended() {
  local cmd="$1"
  local hint="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf "[RECOMMENDED MISSING] %s\n" "$cmd"
    [ -n "$hint" ] && printf "        %s\n" "$hint"
    recommended_missing=1
  fi
}

# Required
check_cmd_required python  "Install Python 3: https://www.python.org/downloads/"
check_cmd_required git     "Install Git: https://git-scm.com/downloads"
check_cmd_required docker  "Install Docker Desktop: https://www.docker.com/products/docker-desktop"
check_cmd_required curl    "Install curl: https://curl.se/"
check_cmd_required awk     "Usually pre-installed on Unix/Git Bash"
check_cmd_required sed     "Usually pre-installed on Unix/Git Bash"
check_cmd_required grep    "Usually pre-installed on Unix/Git Bash"

# Recommended
check_cmd_recommended shellcheck "Install shellcheck: https://www.shellcheck.net/"
check_cmd_recommended shfmt     "Install shfmt: https://github.com/mvdan/sh"
check_cmd_recommended jq        "Install jq: https://stedolan.github.io/jq/"
check_cmd_recommended node      "Install Node.js: https://nodejs.org/ (only needed for JS tooling)"
check_cmd_recommended php       "Install PHP CLI: https://www.php.net/ (only needed for local PHP validation)"

# Python modules
if command -v python >/dev/null 2>&1; then
  if ! python -c 'import tiktoken' >/dev/null 2>&1; then
    printf "[RECOMMENDED MISSING] tiktoken (Python module)\n"
    printf "        Install via: pip install tiktoken\n"
    recommended_missing=1
  fi
  if ! python -c 'import bs4' >/dev/null 2>&1; then
    printf "[RECOMMENDED MISSING] beautifulsoup4 (Python module)\n"
    printf "        Install via: pip install beautifulsoup4\n"
    recommended_missing=1
  fi
fi

if [ $missing -eq 0 ]; then
  echo "All required tooling is present."
  if [ $recommended_missing -ne 0 ]; then
    echo ""
    echo "Note: Some recommended tools are missing. Install them to improve workflow robustness." >&2
  fi
else
  echo ""
  echo "One or more required tools are missing. Install them and rerun this script." >&2
  exit 1
fi
