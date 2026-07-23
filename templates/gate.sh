#!/usr/bin/env bash
# Deterministic review gate — TEMPLATE.
# Copy to <your-repo>/scripts/gate.sh and replace the CHECK section with your
# project's real commands. review-worker and delivery run this before any
# judgment review; exit 0 = PASS, exit 1 = FAIL.
set -uo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo"
failures=()
warnings=()

echo "[1/2] project checks..."
# --- CHECK section: replace with your project's build/lint/test commands ---
if out="$(npm test 2>&1)"; then   # e.g. npm test / mvn -q verify / pytest -q
  echo "  OK"
else
  failures+=("project checks failed")
  echo "$out" | tail -n 25
fi
# ---------------------------------------------------------------------------

echo "[2/2] git state..."
if [ -n "$(git status --porcelain)" ]; then
  failures+=("working tree not clean (commit your checkpoints):
$(git status --porcelain)")
else
  echo "  clean"
fi
if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  ahead="$(git rev-list --count '@{u}..HEAD')"
  if [ "$ahead" -gt 0 ]; then warnings+=("$ahead unpushed commit(s) on current branch"); fi
else
  warnings+=("current branch has no upstream")
fi

echo ""
for w in "${warnings[@]:-}"; do [ -n "$w" ] && echo "WARN: $w"; done
if [ "${#failures[@]}" -gt 0 ]; then
  for f in "${failures[@]}"; do echo "FAIL: $f"; done
  echo "GATE: FAIL"
  exit 1
fi
echo "GATE: PASS"
exit 0
