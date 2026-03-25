#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

REPORT_DIR=".security"
REPORT_PATH="${REPORT_DIR}/last-security-validation.json"

calc_files_hash() {
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s\n' "$@" | sort | sha256sum | awk '{print $1}'
    return 0
  fi

  bash "$SCRIPT_DIR/python-host.sh" - "$@" <<'PY'
import hashlib
import sys

items = sorted(sys.argv[1:])
h = hashlib.sha256()
for item in items:
    h.update(item.encode('utf-8'))
    h.update(b'\n')
print(h.hexdigest())
PY
}

write_report() {
  local outcome="$1"
  local files_hash="$2"

  mkdir -p "$REPORT_DIR"

  bash "$SCRIPT_DIR/python-host.sh" - "$REPORT_PATH" "$MODE" "$outcome" "$files_hash" "$(git rev-parse HEAD)" "$(date +%s)" "${changed_files[@]}" <<'PY'
import json
import sys

report_path = sys.argv[1]
mode = sys.argv[2]
outcome = sys.argv[3]
files_hash = sys.argv[4]
git_head = sys.argv[5]
timestamp_epoch = int(sys.argv[6])
files = sys.argv[7:]

payload = {
    "mode": mode,
    "status": outcome,
    "files_hash": files_hash,
    "git_head": git_head,
    "timestamp_epoch": timestamp_epoch,
    "files": sorted(files),
}

with open(report_path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2, sort_keys=True)
    f.write("\n")
PY
}

MODE="worktree"
RANGE_BASE=""
RANGE_HEAD=""

if [[ "${1:-}" == "--staged" ]]; then
  MODE="staged"
elif [[ "${1:-}" == "--range" ]]; then
  if [[ $# -lt 3 ]]; then
    echo "security-validate-changed.sh: --range requires <base> and <head>." >&2
    exit 2
  fi
  MODE="range"
  RANGE_BASE="$2"
  RANGE_HEAD="$3"
fi

if [[ "$MODE" == "staged" ]]; then
  mapfile -t changed_files < <(bash "$SCRIPT_DIR/list-changed-files.sh" --staged)
elif [[ "$MODE" == "range" ]]; then
  mapfile -t changed_files < <(bash "$SCRIPT_DIR/list-changed-files.sh" --range "$RANGE_BASE" "$RANGE_HEAD")
else
  mapfile -t changed_files < <(bash "$SCRIPT_DIR/list-changed-files.sh")
fi

if [[ ${#changed_files[@]} -eq 0 ]]; then
  echo "Security validation: no changed files detected."
  write_report "passed" "no-files"
  exit 0
fi

# Fast-path: if the security report already covers this exact scan (same mode,
# same HEAD, same file set) and passed, skip re-scanning.
if [[ -f "$REPORT_PATH" ]]; then
  current_hash="$(calc_files_hash "${changed_files[@]}")"
  report_hit=$(bash "$SCRIPT_DIR/python-host.sh" - "$REPORT_PATH" "$MODE" "$current_hash" "$(git rev-parse HEAD)" <<'PY'
import json, sys
report_path, expected_mode, expected_hash, expected_head = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
try:
    with open(report_path, 'r', encoding='utf-8') as f:
        d = json.load(f)
    if (d.get('status') == 'passed'
            and d.get('mode') == expected_mode
            and d.get('files_hash') == expected_hash
            and d.get('git_head') == expected_head):
        print('hit')
    else:
        print('miss')
except Exception:
    print('miss')
PY
  ) || report_hit="miss"
  if [[ "$report_hit" == "hit" ]]; then
    echo "Security validation: cache hit — same range/HEAD already passed. Skipping re-scan."
    exit 0
  fi
fi

is_allowed_secret_file() {
  local file="$1"
  case "$file" in
    specs/app-features/*/docs/credential-registry.md) return 0 ;;
    specs/app-features/*/docs/auth-*.txt) return 0 ;;
    specs/app-features/*/docs/runbook-*.json) return 0 ;;
    *) return 1 ;;
  esac
}

status=0

for file in "${changed_files[@]}"; do
  [[ -f "$file" ]] || continue

  # Avoid self-referential false positives when this validator script changes.
  if [[ "$file" == "scripts/security-validate-changed.sh" ]]; then
    continue
  fi

  if [[ "$MODE" == "staged" ]]; then
    diff_text="$(git diff --cached -U0 -- "$file")"
  elif [[ "$MODE" == "range" ]]; then
    diff_text="$(git diff -U0 "$RANGE_BASE" "$RANGE_HEAD" -- "$file")"
  else
    diff_text="$(git diff -U0 HEAD -- "$file")"
  fi

  added_lines="$(printf '%s\n' "$diff_text" | grep -E '^\+[^+]' || true)"
  [[ -n "$added_lines" ]] || continue

  if ! is_allowed_secret_file "$file"; then
    if printf '%s\n' "$added_lines" | grep -Eqi '(api[_-]?key|secret|site[_-]?token|password)\s*[:=]\s*["\x27][^"\x27]{6,}'; then
      echo "SECURITY FAIL [$file]: potential hardcoded credential/secret in added lines" >&2
      status=1
    fi
  fi

  # Check for __return_true permission callback, but allow if documented as intentional public endpoint
  if printf '%s\n' "$added_lines" | grep -Eqi 'permission_callback.*__return_true'; then
    # Use if/else so pipefail does not abort before we record the finding.
    # Accepted bypass markers: SECURITY-OK, Intentional.*public, public.*endpoint, auth handled in handler.
    if printf '%s\n' "$added_lines" | grep -B1 "permission_callback.*__return_true" \
        | grep -Eqi 'SECURITY-OK|Intentional.*public|public.*endpoint|auth handled in handler'; then
      : # bypass is documented — allowed
    else
      echo "SECURITY FAIL [$file]: REST route with __return_true permission callback added." >&2
      echo "  To allow an intentional public endpoint, add this comment on the line immediately above:" >&2
      echo "    // SECURITY-OK: intentional public endpoint — auth handled in handler." >&2
      status=1
    fi
  fi

  # PHP-specific checks — skip markdown/docs/shell/JS files to avoid false positives
  # from code examples in documentation.
  if [[ "$file" == *.php ]]; then
    if printf '%s\n' "$added_lines" | grep -Eqi '\$_(GET|POST|REQUEST|COOKIE)\['; then
      if ! printf '%s\n' "$added_lines" | grep -Eqi 'sanitize_|wp_unslash|absint|intval|floatval'; then
        echo "SECURITY WARN [$file]: superglobal usage added; verify sanitization/validation" >&2
        status=1
      fi
    fi

    if printf '%s\n' "$added_lines" | grep -Eqi 'wp_remote_(get|post)\s*\(.*http://'; then
      echo "SECURITY FAIL [$file]: insecure http:// remote request added" >&2
      status=1
    fi

    if printf '%s\n' "$added_lines" | grep -Eqi '\$wpdb->(query|get_results|get_row|get_var)\s*\('; then
      if ! printf '%s\n' "$added_lines" | grep -Eqi 'prepare\s*\('; then
        echo "SECURITY WARN [$file]: direct wpdb query call added; verify prepared statements" >&2
        status=1
      fi
    fi
  fi

done

if [[ $status -eq 0 ]]; then
  files_hash="$(calc_files_hash "${changed_files[@]}")"
  write_report "passed" "$files_hash"
  echo "Security validation passed for ${#changed_files[@]} changed file(s)."
else
  files_hash="$(calc_files_hash "${changed_files[@]}")"
  write_report "failed" "$files_hash"
  echo "Security validation failed. Resolve findings before commit/push." >&2
fi

exit $status
