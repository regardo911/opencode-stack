#!/usr/bin/env bash
# Tests for the tools in chapters/. No key, no account, no model.
# cost-dash runs on tests/fixtures (synthetic data); the fan-out and the health check run
# against tests/stub/opencode. Every run uses a throwaway HOME, so nothing lands in yours.
# The last block checks both configs with your real opencode when one is on PATH.
# Usage: bash tests/run.sh        PYTHON=python3.9 bash tests/run.sh
# shellcheck disable=SC2015,SC2001  # `ok` always returns 0, so `test && ok || bad` cannot run both
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="${PYTHON:-python3}"
DASH="$ROOT/chapters/09-cost-dashboard/cost-dash"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" TZ=UTC
mkdir -p "$HOME"
PASS=0; FAIL=0

ok()   { PASS=$((PASS+1)); echo "ok   $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL $1"; [ -n "${2:-}" ] && echo "$2" | sed 's/^/     /'; }
has()  { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "expected: $3"$'\n'"got: $2" ;; esac; }
lacks() { case "$2" in *"$3"*) bad "$1" "did not expect: $3" ;; *) ok "$1" ;; esac; }

OC="$TMP/opencode.db"
"$PY" -c 'import sqlite3,sys; sqlite3.connect(sys.argv[1]).executescript(open(sys.argv[2]).read())' \
  "$OC" "$ROOT/tests/fixtures/opencode-synthetic.sql"
dash() { "$PY" "$DASH" "$1" --opencode-db "$OC" --db "$TMP/cost.db" "${@:2}"; }

echo "# cost-dash (chapter 9)"
out="$(dash today --date 2026-05-06)"
has  "today: book's ISO week for 2026-05-06" "$out" "2026-W19 Wednesday"
has  "today: run-rate read from the messages" "$out" "today's run-rate:    \$1.00  (warning at \$0.80, cutoff \$1.50)"
has  "today: top model is a model id" "$out" "top model:           opencode-go/kimi-k2.7-code"
has  "today: top provider is a provider, not a model" "$out" "top provider:        opencode-go  ("
has  "today: week so far against the \$7.00 target" "$out" "(target \$7.00,"
has  "today: three token shares, each labelled" "$out" "token split:         input "
out="$(dash today --date 2026-05-06 --warn 1.25 --week-target 10)"
has  "today: thresholds come from flags" "$out" "(warning at \$1.25, cutoff \$1.50)"

rows="$(sqlite3 "$TMP/cost.db" "SELECT agent FROM sessions WHERE session_id='ses_synth_mon_refactor' ORDER BY agent" 2>/dev/null \
  || "$PY" -c 'import sqlite3,sys; print("\n".join(r[0] for r in sqlite3.connect(sys.argv[1]).execute("SELECT agent FROM sessions WHERE session_id=? ORDER BY agent",("ses_synth_mon_refactor",))))' "$TMP/cost.db")"
[ "$rows" = $'fixer\norchestrator' ] && ok "one row per (session, agent, model)" || bad "one row per (session, agent, model)" "$rows"

wk="$("$PY" - "$DASH" <<'EOF'
import importlib.machinery, importlib.util, sys, datetime as dt
loader = importlib.machinery.SourceFileLoader("cost_dash", sys.argv[1])
spec = importlib.util.spec_from_loader("cost_dash", loader); m = importlib.util.module_from_spec(spec); loader.exec_module(m)
print(m.iso_week(dt.date(2026, 5, 6)), m.iso_week(dt.date(2021, 1, 1)))
EOF
)"
[ "$wk" = "2026-W19 2020-W53" ] && ok "iso_week: 2026-W19, and the year-boundary week" || bad "iso_week" "$wk"

dash tag ses_synth_wed_redesign_2 refactor >/dev/null
dash today --date 2026-05-06 >/dev/null
out="$(dash report --week 2026-W19 --out "$TMP/w19.md")"
has  "tag: survives the next sync" "$out" "- refactor"
has  "report: flags the day over the warning" "$out" "Wednesday 2026-05-06 cost \$1.00 (warning at \$0.80)."
has  "report: never guesses a cause" "$out" "cause: unknown, you must observe this"
has  "report: splits cost by agent" "$out" "By agent:"
[ -s "$TMP/w19.md" ] && ok "report: writes the Markdown file" || bad "report: writes the Markdown file"
out="$(dash report --week 2026-W19 --out "$TMP/w19b.md" --spike 1.5)"
has  "report: flags a session far above the week's average" "$out" "session 'ses_synth_wed_redesign_3' input tokens"

cd "$TMP" || exit 1
out="$(dash log --project p03 --session ses_synth_mon_refactor --csv "$TMP/cost-log.csv")"
dash log --project p03 --session ses_synth_mon_refactor --csv "$TMP/cost-log.csv" >/dev/null
csv="$(cat "$TMP/cost-log.csv")"
[ "$(grep -c '^date,project,model,input_tokens,output_tokens,cost_usd$' "$TMP/cost-log.csv")" = 1 ] \
  && ok "log: the book's CSV header, written once" || bad "log: CSV header" "$csv"
has  "log: one row per agent, ISO-week date" "$csv" "2026-W19,p03,opencode-go/kimi-k2.7-code,8000,1030,0.0115"
has  "log: duration read from message times" "$out" "duration: "
has  "log: diff quality is left to you" "$out" "diff quality: unknown, you must observe this"
out="$("$PY" "$DASH" log --export "$ROOT/tests/fixtures/export-synthetic.json" --db "$TMP/exp.db" --project p03 --csv "$TMP/exp.csv")"
has  "log --export: reads an opencode export file" "$out" "session ses_synth_mon_refactor: 2 row(s)"

now_ms="$("$PY" -c 'import time; print(int(time.time()*1000))')"
"$PY" - "$OC" "$now_ms" <<'EOF'
import json, sqlite3, sys
c = sqlite3.connect(sys.argv[1]); t = int(sys.argv[2])
d = {"role": "assistant", "agent": "orchestrator", "providerID": "opencode-go", "modelID": "kimi-k2.7-code", "cost": 0.9,
     "tokens": {"input": 1, "output": 1, "reasoning": 0, "cache": {"read": 0, "write": 0}}, "time": {"created": t, "completed": t}}
c.execute("INSERT INTO message VALUES ('msg_now', 'ses_now', ?, ?, ?)", (t, t, json.dumps(d))); c.commit()
EOF
out="$(dash alert)"; rc=$?
[ $rc = 1 ] && ok "alert: exits 1 at the \$0.80 warning" || bad "alert: exit code" "rc=$rc $out"
[ ! -e "$TMP/cooldown" ] && ok "alert: no cooldown file without --cutoff" || bad "alert: cooldown written without --cutoff"
dash alert --cutoff-at 0.85 --cutoff >/dev/null; rc=$?
[ $rc = 2 ] && [ -f "$TMP/cooldown" ] && ok "alert --cutoff: writes the cooldown file" || bad "alert --cutoff" "rc=$rc"
out="$(dash reset --reason "I know what I'm doing")"
[ ! -e "$TMP/cooldown" ] && grep -q "I know what I'm doing" "$TMP/resets.log" \
  && ok "reset --reason: clears the file and records the reason" || bad "reset" "$out"

before="$(cksum < "$OC")"; dash today >/dev/null; after="$(cksum < "$OC")"
[ "$before" = "$after" ] && ok "opencode's database is opened read-only" || bad "opencode db changed"

out="$("$PY" - "$DASH" "$OC" "$TMP/net.db" <<'EOF' 2>&1
import runpy, socket, sys
def refuse(*a, **k): raise RuntimeError("network call attempted")
socket.socket = refuse; socket.create_connection = refuse
dash, oc, db = sys.argv[1:4]
sys.argv = [dash, "report", "--opencode-db", oc, "--db", db, "--week", "2026-W19", "--out", db + ".md"]
try:
    runpy.run_path(dash, run_name="__main__")
except SystemExit as e:
    print("exit", e.code)
EOF
)"
lacks "no network: report runs with sockets disabled" "$out" "network call attempted"

echo "# worktree-fanout.sh (chapter 8)"
export PATH="$ROOT/tests/stub:$PATH" STUB_LOG="$TMP/stub.log"
G="git -c user.name=test -c user.email=test@example.com"
mkdir -p "$TMP/fan/app" && cd "$TMP/fan/app" || exit 1
git init -q && git checkout -q -b master 2>/dev/null; echo "export const x = 1;" > users.ts
git add -A && $G commit -qm init
out="$(GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com \
  N=2 bash "$ROOT/chapters/08-skills-and-fanout/worktree-fanout.sh" "Refactor users.ts" 2>&1)"; rc=$?
[ $rc = 0 ] && ok "fan-out: runs to the end on a master branch" || bad "fan-out exit" "rc=$rc $out"
has  "fan-out: prints each diff against the start commit" "$out" "+// edit from app-fan-2"
has  "fan-out: calls opencode run with the agent" "$(cat "$TMP/stub.log")" "run --agent fixer --print-logs Refactor users.ts"
$G merge -q fanout/2 >/dev/null 2>&1
grep -q "edit from app-fan-2" users.ts && ok "fan-out: git merge fanout/2 brings the edit in" || bad "merge brought nothing"
git worktree remove --force ../app-fan-1 && git branch -q -D fanout/1 && ok "fan-out: cleanup with --force" || bad "cleanup"
git worktree remove --force ../app-fan-2; git branch -q -D fanout/2
: > "$TMP/stub.log"
GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com \
  N=1 AGENT=fixer-deepseek bash "$ROOT/chapters/08-skills-and-fanout/worktree-fanout.sh" "x" >/dev/null 2>&1
has  "fan-out: AGENT picks another agent" "$(cat "$TMP/stub.log")" "run --agent fixer-deepseek"

echo "# health-check.sh (chapter 11)"
mkdir -p "$TMP/skills"
out="$(SKILLS_DIR="$TMP/skills" COST_DB="$TMP/cost.db" bash "$ROOT/chapters/11-health-check/health-check.sh")"; rc=$?
[ $rc = 0 ] && ok "health-check: 8 PASS exits 0" || bad "health-check all pass" "$out"
has  "health-check: ripgrep check uses debug rg files" "$out" "ripgrep present (debug rg files)         PASS"
out="$(SKILLS_DIR="$TMP/nope" COST_DB="$TMP/cost.db" bash "$ROOT/chapters/11-health-check/health-check.sh")"; rc=$?
[ $rc = 1 ] && ok "health-check: a FAIL exits 1" || bad "health-check missing skills dir" "$out"

echo "# skills (chapters 8 and 10)"
for f in "$ROOT"/chapters/08-skills-and-fanout/skills/*/SKILL.md "$ROOT"/chapters/10-ship-the-last-two/skill-template/SKILL.md; do
  dir="$(basename "$(dirname "$f")")"
  name="$(sed -n 's/^name: *//p' "$f" | head -1)"
  desc="$(sed -n 's/^description: *//p' "$f" | head -1)"
  [ "$dir" = "skill-template" ] && dir="$name"
  if [ "$(head -1 "$f")" = "---" ] && [ "$name" = "$dir" ] && echo "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' \
     && [ ${#name} -le 64 ] && [ ${#desc} -ge 1 ] && [ ${#desc} -le 1024 ]; then ok "skill frontmatter: $name"
  else bad "skill frontmatter: $f" "name=$name dir=$dir desc=${#desc} chars"; fi
done

echo "# configs (chapters 6 and 7)"
found="$(cd "$ROOT" && find . -path ./.git -prune -o \( -name 'opencode.json' -o -name 'opencode.jsonc' -o -name '.opencode' -o -name '.claude' -o -name '.agents' -o -name '.opencodeignore' \) -print)"
[ -z "$found" ] && ok "nothing in the clone that opencode would load by itself" || bad "files opencode would load" "$found"
REAL_OC="$(PATH="${PATH#"$ROOT/tests/stub:"}" command -v opencode || true)"
if [ -z "$REAL_OC" ]; then
  echo "skip opencode debug config: no opencode on PATH"
else
  for cfg in 06-routing/opencode.ch06.jsonc:orchestrator 07-self-host/opencode.ch07.jsonc:local-fixer; do
    p="$TMP/cfg-${cfg%%/*}"; mkdir -p "$p/xdg" && cp "$ROOT/chapters/${cfg%%:*}" "$p/opencode.json"
    if (cd "$p" && XDG_CONFIG_HOME="$p/xdg" XDG_DATA_HOME="$p/xdg" XDG_CACHE_HOME="$p/xdg" XDG_STATE_HOME="$p/xdg" \
          "$REAL_OC" debug agent "${cfg##*:}" >/dev/null 2>&1); then ok "opencode accepts ${cfg%%:*} (${cfg##*:} resolves)"
    else bad "opencode rejects ${cfg%%:*}"; fi
  done
fi

echo
echo "$PASS passed, $FAIL failed"
[ "$PASS" -gt 0 ] && [ "$FAIL" = 0 ]
