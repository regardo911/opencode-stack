# Book fixes

Where the book's configs, commands and scripts fail, the output that shows it, and what this repo does instead. Checked on 2026-11-09 with opencode 1.4.3 and 1.19.5, Python 3.9.6, Ollama and git on macOS.

## Chapter 4: `opencode stats` hides the model table

The book says `opencode stats` "lists token usage by provider and model". Both versions print the overview, cost and tool tables only; the model table needs a flag:

```
$ opencode stats --help
      --models      show model statistics (default: hidden). Pass a number to show top N, otherwise
```

Use `opencode stats --models`. For per-agent numbers, `cost-dash log` reads them from the session.

## Chapter 6: `opencode/` is the Zen prefix, not the Go one

The book writes every Go model as `opencode/<id>`. opencode resolves that prefix to the provider called OpenCode, which is Zen, the per-request tier:

```
$ opencode debug agent orchestrator        # the book's ch06 config, opencode 1.19.5
  "model": {
    "providerID": "opencode",
    "modelID": "kimi-k2.6"
  },
```

The model catalog opencode 1.19.5 downloaded lists the two as separate providers with separate endpoints:

```
opencode | OpenCode | https://opencode.ai/inference/openai/v1
opencode-go | OpenCode Go | https://opencode.ai/inference/go/openai/v1
```

The OpenCode Go docs page says to set the model "using the format opencode-go/<model-id>". `opencode.ch06.jsonc` uses `opencode-go/`.

## Chapter 6: the four models have left OpenCode Go

On 2026-11-09 none of the book's four ids was in the `opencode-go` provider of that same catalog, and none was on the Go docs page's model list:

```
kimi-k2.6 | in opencode: True | in opencode-go: False
qwen3.5-plus | in opencode: True | in opencode-go: False
glm-5 | in opencode: True | in opencode-go: False
deepseek-v4-flash | in opencode: True | in opencode-go: False
```

`opencode.ch06.jsonc` uses the closest id in the same family that Go listed that day (`kimi-k2.7-code`, `qwen3.7-plus`, `glm-5.2`, `deepseek-v4.1-flash`) and keeps the book's id in a comment on each line. This list will move again; `/models` in the TUI shows yours.

## Chapter 7: the Ollama provider block

The book (and appendix B.2) puts `baseURL` directly under `provider.ollama`. opencode 1.4.3 refuses the file (first run in a fresh data folder, so the migration lines print too):

```
$ opencode debug config
Performing one time database migration, may take a few minutes...
sqlite-migration:done
Database migration complete.
Error: Configuration is invalid at /tmp/work/p-b1/opencode.json
↳ Unrecognized key: "baseURL" provider.ollama
```

opencode 1.19.5 accepts the file and drops the key:

```
$ opencode debug config | grep -A1 '"provider"'
  "provider": {
    "ollama": {}
```

Then a run prints nothing and does not finish (stopped by `timeout 120`, exit 124). With the model set to `ollama/llama3.1:8b`, a tag that was pulled, the log says why:

```
$ opencode run --print-logs --agent local-fixer "Reply with the single word: pong" 2>&1 | grep -E "ERROR|^Error" | cut -c1-400
timestamp=2026-11-09T19:06:35.389Z level=ERROR run=397cada4 message=failed ref=err_5bb37122 error="ProviderModelNotFoundError: Model not found: ollama/llama3.1:8b. Did you mean: ollama-cloud?" cause="ProviderModelNotFoundError: Model not found: ollama/llama3.1:8b. Did you mean: ollama-cloud?\n    at <anonymous> (/$bunfs/root/chunk-tqdk3s07.js:2:64514)\n    at SessionPrompt.getModel (/$bunfs/root/c
Error: {
```

With `npm`, `options.baseURL` and a `models` list, the shipped `opencode.ch07.jsonc` answers (1.19.5, `ollama pull qwen3.5:9b` done, 146 s on this Mac):

```
$ opencode run --agent local-fixer "Reply with the single word: pong"

> local-fixer · qwen3.5:9b

pong
```


## Chapter 7: the Ollama tags

```
$ ollama pull qwen3.6-plus
Error: pull model manifest: file does not exist
$ ollama pull qwen3.5-plus
Error: pull model manifest: file does not exist
$ ollama pull kimi-k2.6
Error: pull model manifest: file does not exist

"kimi-k2.6:cloud" is available as a cloud model. Try:
  ollama pull kimi-k2.6:cloud
```

The book's own appendix A says Kimi K2.6 has "Closed weights; not self-hostable", and Ollama offers it only as a cloud model. `opencode.ch07.jsonc` uses `qwen3.5:9b` (6.6 GB) for both fixers and `qwen3.6:27b` (17.8 GB) for `orchestrator-local`.

## Chapter 8: the fan-out opens six TUIs

The printed line starts opencode with no subcommand, which is the full-screen TUI:

```
opencode --agent fixer --prompt "$PROMPT" --print-logs > "../fan-$i.log" 2>&1
```

`opencode --help` lists that form as `opencode [project]  start opencode tui`, and `opencode run [message..]  run opencode with a message` as the one that runs a prompt and exits. Run once, the book's way, in the background with no terminal and a two-minute limit (opencode 1.19.5, a `fixer` agent on local `llama3.1:8b`):

```
$ ( timeout 120 opencode --agent fixer --prompt "Reply with the single word: pong" --print-logs > ../tui2.log 2>&1; echo "opencode exit=$?" ) & wait
opencode exit=124
```

Ollama's log shows the model's last reply finishing 23 seconds after launch; the TUI was still open at 120 s, when `timeout` killed it. In the script, `wait` would sit there the same way. `worktree-fanout.sh` runs `opencode run --agent "$AGENT" --print-logs "$PROMPT"`. The same check with `opencode run` and the same agent exited 0 after 3 seconds.

A real run of the fixed script, `N=2`, a `fixer` on local `qwen3.5:9b`, on a `master` repo: both `opencode run` calls returned, one worktree had the edit and one had none, and the script printed:

```
=== Worktree 1 diff ===
=== Worktree 2 diff ===
diff --git a/users.ts b/users.ts
index 910f210..be8a9ed 100644
--- a/users.ts
+++ b/users.ts
@@ -1,3 +1,7 @@
 export function greet(name: string): string {
   return "hello " + name;
 }
+
+export function double(x: number): number {
+  return x * 2;
+}

Pick the winner: git merge fanout/<N>
Cleanup each loser: git worktree remove --force ../app-fan-<N> && git branch -D fanout/<N>
```

`git merge fanout/2` then fast-forwarded. Agent 1's log shows what `bash: "ask"` does under `opencode run`:

```
! permission requested: bash (cat -A /tmp/work/realrun/app-fan-1/users.ts, head -5); auto-rejecting
```

## Chapter 8: `git merge fanout/3` merges nothing

The printed script never commits, so every agent's edit stays uncommitted in its worktree. Run on a `main` repo with a stand-in `opencode` that appends one line to `users.ts`:

```
$ git merge fanout/3
Already up to date.
$ cat users.ts
export const x = 1;
```

`worktree-fanout.sh` commits each worktree after its agent exits (when there is a change), then prints the diff. The same merge then fast-forwards:

```
$ git merge fanout/3
Updating 3567cd8..6d74100
Fast-forward
 users.ts | 1 +
 1 file changed, 1 insertion(+)
```

## Chapter 8: the cleanup loop stops at every worktree

```
$ for i in 1 2 4 5 6; do git worktree remove "../your-repo-fan-$i"; git branch -D "fanout/$i"; done
fatal: '../your-repo-fan-1' contains modified or untracked files, use --force to delete it
error: cannot delete branch 'fanout/1' used by worktree at '/tmp/work/book-fanout2/your-repo-fan-1'
fatal: '../your-repo-fan-2' contains modified or untracked files, use --force to delete it
error: cannot delete branch 'fanout/2' used by worktree at '/tmp/work/book-fanout2/your-repo-fan-2'
fatal: '../your-repo-fan-4' contains modified or untracked files, use --force to delete it
error: cannot delete branch 'fanout/4' used by worktree at '/tmp/work/book-fanout2/your-repo-fan-4'
fatal: '../your-repo-fan-5' contains modified or untracked files, use --force to delete it
error: cannot delete branch 'fanout/5' used by worktree at '/tmp/work/book-fanout2/your-repo-fan-5'
fatal: '../your-repo-fan-6' contains modified or untracked files, use --force to delete it
error: cannot delete branch 'fanout/6' used by worktree at '/tmp/work/book-fanout2/your-repo-fan-6'
```

The losers are thrown away on purpose, so the loop needs `git worktree remove --force`. The chapter 8 README prints it that way.

## Chapter 8: `git diff main` on a repo without `main`

On a repo whose branch is `master` (the book's own Project #10 target, `oh-my-opencode-slim`, is one), the printed script dies at the first diff, after all six agents have run:

```
=== Worktree 1 diff ===
fatal: ambiguous argument 'main': unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
'git <command> [<revision>...] -- [<file>...]'
```

Exit code 128. `worktree-fanout.sh` records the commit it started from and diffs against that.

## Chapter 9: the parser sketch does not import on Python 3.9

```
$ /usr/bin/python3 book_parser.py          # ch09's sketch as printed; macOS Python 3.9.6
Traceback (most recent call last):
  File "/tmp/work/proofs/book_parser.py", line 7, in <module>
    def parse_session(session_file: Path) -> dict | None:
TypeError: unsupported operand type(s) for |: 'type' and 'NoneType'
```

`cost-dash` uses `Optional`.

## Chapter 9: the ISO week expression

```
$ python3 -c 'print("2026-05-06T10:00:00Z"[:8].replace("-W", "-W"))'
2026-05-
```

The comment beside it says `'2026-W19'`. `cost-dash` builds the week from `date.isocalendar()` and gets `2026-W19` for that date.

## Chapter 9: opencode keeps no session JSON files

The sketch reads one JSON file per session from `~/.local/share/opencode/`. That folder holds a SQLite database:

```
$ ls ~/.local/share/opencode/
log
opencode.db
opencode.db-shm
opencode.db-wal
repos
snapshot
```

Run on a real session (`opencode export <id>`, the format chapter 9 tells you to check), the sketch's `parse_session` finds none of its keys and returns nothing:

```
$ python3 b8.py export.json
parse_session(export of a real session) -> None
```

Model, agent, tokens and cost sit on each assistant message, so one session can hold both the orchestrator and the fixer. `cost-dash` reads `opencode.db` read-only (or an export file) and keeps one row per session, agent and model. Its `sessions` table has the book's columns plus `agent`.

## Chapter 9: opencode never checks the cooldown flag

The book says the next `opencode` invocation checks the cooldown flag and refuses to launch. It launches:

```
$ ls ~/.local/share/opencode-dashboard/
cooldown
$ opencode --version
1.19.5
```

The chapter 9 README has a short shell function that does the check. With it loaded, the same command stops:

```
$ opencode --version
cost cooldown: $1.70 today (cutoff $1.50), set 2026-11-09T14:02:11
clear it with: cost-dash reset --reason "..."
```

(exit code 1).

## Chapter 11: the ripgrep check fails on every machine

`opencode debug rg` is a group of subcommands. Run bare, it prints its help and exits 1, ripgrep or not (`/opt/homebrew/bin/rg`, ripgrep 15.2.0, was installed for this run):

```
$ opencode debug rg
opencode debug rg

ripgrep debugging utilities

Commands:
  opencode debug rg files             list files using ripgrep
  opencode debug rg search <pattern>  search file contents using ripgrep
```

So the printed health check fails a healthy install:

```
OpenCode weekly health check, 2026-W46
─────────────────────────────────────────────
opencode binary on PATH                  PASS
opencode --version reports OK            PASS
config parses (debug paths)              PASS
config keys (debug config)               PASS
ripgrep present (debug rg)               FAIL
skills directory readable                FAIL
providers list resolves                  PASS
cost dashboard recent rows               FAIL
─────────────────────────────────────────────
Summary: 5 PASS, 3 FAIL
```

`health-check.sh` runs `opencode debug rg files`. Same machine:

```
ripgrep present (debug rg files)         PASS
...
Summary: 6 PASS, 2 FAIL
```

The two FAILs left are true on that machine: no skills folder yet, no cost-dash store yet.

## Chapter 12: `opencode debug skill <name>` prints help

```
$ opencode debug skill typescript
opencode debug skill

list all available skills
```

Exit code 1 on both versions, with the skill installed. List them all and look for yours:

```
$ opencode debug skill | grep '"name": "typescript"'
    "name": "typescript",
```
