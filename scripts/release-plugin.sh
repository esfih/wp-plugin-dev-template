#!/usr/bin/env bash
# release-plugin.sh — full release workflow orchestrator.
#
# Runs in sequence:
#   1. Check for Windows reserved-name files that break git add -A
#   2. Run security validation on staged + unstaged changes
#   3. Bump plugin version (Version: header + WMOS_VERSION constant)
#   4. Stage all changes (excluding Windows reserved names)
#   5. Commit with a single-line message
#   6. Create and push the version tag
#   7. Build the release zip
#   8. Retrieve GITHUB_TOKEN from Git Credential Manager
#   9. Publish asset to GitHub release
#  10. Print the confirmed browser_download_url
#
# Usage:
#   scripts/release-plugin.sh --plugin <slug> --version <version>
#
# Example:
#   scripts/release-plugin.sh --plugin webmasteros --version 0.1.17
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  scripts/release-plugin.sh --plugin <slug> --version <version>

Arguments:
  --plugin <slug>      Plugin slug, e.g. webmasteros
  --version <version>  Release version, e.g. 0.1.17

Required in environment (auto-retrieved if absent):
  GITHUB_TOKEN         GitHub token with repo/release write access.
  GITHUB_REPO          owner/repo, e.g. esfih/WebMasterOS  (default: read from git remote)
EOF
}

PLUGIN=""
VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plugin)  PLUGIN="$2";  shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$PLUGIN" || -z "$VERSION" ]]; then
  usage
  exit 2
fi

TAG="${PLUGIN}-v${VERSION}"

# ── Derive GITHUB_REPO from git remote if not set ────────────────────────────
if [[ -z "${GITHUB_REPO:-}" ]]; then
  remote_url=$(git remote get-url origin 2>/dev/null || true)
  if [[ -z "$remote_url" ]]; then
    echo "ERROR: GITHUB_REPO is not set and cannot determine it from git remote." >&2
    exit 2
  fi
  # Strip scheme + host, remove trailing .git
  GITHUB_REPO=$(printf '%s' "$remote_url" \
    | sed -E 's|.*github\.com[:/]||; s|\.git$||')
fi

# ── Retrieve GITHUB_TOKEN from Git Credential Manager if not set ─────────────
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "GITHUB_TOKEN not set — retrieving from Git Credential Manager..."
  token_line=$(git credential fill <<'EOF'
protocol=https
host=github.com

EOF
  )
  GITHUB_TOKEN=$(printf '%s\n' "$token_line" | grep '^password=' | cut -d= -f2-)
  if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "ERROR: could not retrieve GITHUB_TOKEN from Git Credential Manager." >&2
    exit 2
  fi
  export GITHUB_TOKEN
fi

# ── Step 1: Check for Windows reserved-name files ────────────────────────────
echo "==> [1/10] Checking for Windows reserved-name files..."
reserved=$(git status --porcelain 2>/dev/null \
  | awk '{print $NF}' \
  | grep -Exi 'nul|con|prn|aux|com[1-9]|lpt[1-9]' || true)
if [[ -n "$reserved" ]]; then
  echo "WARNING: Windows reserved-name files found in worktree (will be skipped by git add):"
  echo "$reserved"
fi

# ── Step 2: Security validation ──────────────────────────────────────────────
echo "==> [2/10] Running security validation..."
"${SCRIPT_DIR}/security-validate-changed.sh" --staged || {
  echo "ERROR: security validation failed — fix all FAIL items before releasing." >&2
  exit 1
}

# ── Step 3: Bump version ─────────────────────────────────────────────────────
echo "==> [3/10] Bumping version to ${VERSION}..."
"${SCRIPT_DIR}/bump-version.sh" --plugin "$PLUGIN" --to "$VERSION"

# ── Step 4: Stage all changes (skip Windows reserved names) ──────────────────
echo "==> [4/10] Staging changes..."
# Collect paths from git status, excluding Windows reserved names
mapfile -t staged_paths < <(git status --porcelain \
  | awk '{print $NF}' \
  | grep -Evxi 'nul|con|prn|aux|com[1-9]|lpt[1-9]' || true)
if [[ ${#staged_paths[@]} -eq 0 ]]; then
  echo "No changes to stage."
else
  git add "${staged_paths[@]}"
fi

# ── Step 5: Commit ───────────────────────────────────────────────────────────
echo "==> [5/10] Committing..."
# Single-line -m only — multi-line hangs Git Bash on Windows
git commit -m "chore(release): bump ${PLUGIN} to ${VERSION}" || echo "(Nothing new to commit — continuing.)"
git log --oneline -1

# ── Step 6: Tag and push ─────────────────────────────────────────────────────
echo "==> [6/10] Creating tag ${TAG} and pushing..."
git tag -a "$TAG" -m "Release ${TAG}" 2>/dev/null || echo "(Tag ${TAG} already exists — reusing.)"
git push origin main --follow-tags

# ── Step 7: Build release zip ────────────────────────────────────────────────
echo "==> [7/10] Building release zip..."
"${SCRIPT_DIR}/build-release-zip.sh" \
  --source "${PLUGIN}" \
  --plugin-slug "${PLUGIN}" \
  --version "${VERSION}" \
  --bootstrap "${PLUGIN}.php"

ZIP_PATH="output/releases/${PLUGIN}-${VERSION}.zip"
if [[ ! -f "$ZIP_PATH" ]]; then
  echo "ERROR: expected zip not found at ${ZIP_PATH}" >&2
  exit 1
fi

# ── Step 8: GITHUB_TOKEN already retrieved above ─────────────────────────────
echo "==> [8/10] GITHUB_TOKEN ready."

# ── Step 9: Publish asset to GitHub release ──────────────────────────────────
echo "==> [9/10] Publishing ${ZIP_PATH} to GitHub release ${TAG}..."
download_url=$("${SCRIPT_DIR}/publish-release-asset.sh" \
  --repo "$GITHUB_REPO" \
  --tag  "$TAG" \
  --asset "$ZIP_PATH" \
  --title "Release ${VERSION}" \
  --notes "Release ${PLUGIN} v${VERSION}")

# ── Step 10: Print result ────────────────────────────────────────────────────
echo ""
echo "==> [10/10] Release complete."
echo "    Plugin : ${PLUGIN} v${VERSION}"
echo "    Tag    : ${TAG}"
echo "    ZIP    : ${ZIP_PATH}"
echo "    URL    : ${download_url}"
