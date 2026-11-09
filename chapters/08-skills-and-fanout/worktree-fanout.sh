#!/usr/bin/env bash
# worktree-fanout.sh: spin up N parallel OpenCode agents, each in its own
# git worktree, all running the same prompt. Pick the winning diff at the end.
#
# Chapter 8, Project #7, "The setup script". What differs from the printed script (BOOK-FIXES.md, chapter 8):
#   - `opencode --agent fixer --prompt ...` opens the TUI; `opencode run` is the one that runs and exits.
#   - each worktree commits what its agent changed, so `git merge fanout/3` has something to merge.
#   - diffs are taken against the commit you started from, so a repo whose branch is not `main` works.
#   - the cleanup line it prints says --force (the losing worktrees hold uncommitted files).
#   - N and AGENT come from the environment; unset, they are the book's 6 and fixer:
#       N=2 AGENT=fixer-deepseek tools/worktree-fanout.sh "<prompt>"
# Run it in YOUR project. It makes N sibling folders next to the repo: ../<repo>-fan-1 and so on.

# shellcheck disable=SC2086  # $(seq 1 $N) is the book's line, kept as printed; N is a number
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
PROMPT="${1:?usage: worktree-fanout.sh '<prompt>'}"
N="${N:-6}"
AGENT="${AGENT:-fixer}"
PARENT="$(dirname "$REPO_ROOT")"
BASE="$(basename "$REPO_ROOT")"
START="$(git rev-parse HEAD)"

# N worktrees, all cut from the same commit, so the diffs compare like with like
for i in $(seq 1 $N); do
  WORKTREE="$PARENT/$BASE-fan-$i"
  git worktree add -b "fanout/$i" "$WORKTREE" HEAD
  echo "Created worktree: $WORKTREE"
done

# Launch N OpenCode agents in parallel
for i in $(seq 1 $N); do
  WORKTREE="$PARENT/$BASE-fan-$i"
  (
    cd "$WORKTREE"
    opencode run --agent "$AGENT" --print-logs "$PROMPT" > "../fan-$i.log" 2>&1 \
      || echo "agent $i: opencode exited $? (see ../fan-$i.log)"
  ) &
done

wait

# Commit what each agent changed, then show the diffs
for i in $(seq 1 $N); do
  WORKTREE="$PARENT/$BASE-fan-$i"
  git -C "$WORKTREE" add -A
  git -C "$WORKTREE" diff --cached --quiet || git -C "$WORKTREE" commit -q -m "fanout/$i: ${PROMPT:0:60}"
  echo "=== Worktree $i diff ==="
  git -C "$WORKTREE" diff "$START" HEAD
done

echo ""
echo "Pick the winner: git merge fanout/<N>"
echo "Cleanup each loser: git worktree remove --force ../$BASE-fan-<N> && git branch -D fanout/<N>"
