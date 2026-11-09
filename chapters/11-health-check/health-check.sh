#!/usr/bin/env bash
# health-check.sh: weekly OpenCode setup verification.
#
# Chapter 11, "The 10-Minute Weekly Health Check". What differs from the book (BOOK-FIXES.md):
#   `opencode debug rg` is a group of subcommands; run bare it prints help and exits 1,
#   so a machine WITH ripgrep failed the check. This file runs `opencode debug rg files`,
#   which passes when opencode can run ripgrep (yours, or the copy it downloads itself).
# The two paths it reads can point somewhere else:
#   SKILLS_DIR=~/my-skills COST_DB=~/cost.db bash tools/health-check.sh

set +e
PASS=0
FAIL=0
SKILLS_DIR="${SKILLS_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills}"
COST_DB="${COST_DB:-$HOME/.local/share/opencode-dashboard/cost.db}"

check() {
  local name=$1
  local cmd=$2
  printf "%-40s " "$name"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "PASS"
    PASS=$((PASS+1))
  else
    echo "FAIL"
    FAIL=$((FAIL+1))
  fi
}

echo "OpenCode weekly health check, $(date +%Y-W%V)"
echo "─────────────────────────────────────────────"

check "opencode binary on PATH"        "command -v opencode"
check "opencode --version reports OK"   "opencode --version"
check "config parses (debug paths)"     "opencode debug paths"
check "config keys (debug config)"      "opencode debug config"
check "ripgrep present (debug rg files)" "opencode debug rg files"
check "skills directory readable"       "test -d \"$SKILLS_DIR\""
check "providers list resolves"         "opencode providers list"
check "cost dashboard recent rows"      "test -f \"$COST_DB\" && sqlite3 \"$COST_DB\" 'SELECT COUNT(*) FROM sessions WHERE started_at > date(\"now\", \"-7 days\")' | grep -v '^0$'"

echo "─────────────────────────────────────────────"
echo "Summary: $PASS PASS, $FAIL FAIL"
[[ $FAIL -gt 0 ]] && exit 1 || exit 0
