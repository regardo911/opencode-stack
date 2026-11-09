# Chapter 9: cost-dash

The book describes this dashboard and leaves the code to you. [`cost-dash`](cost-dash) is that code: one Python file, standard library only, Python 3.9 or newer.

It reads opencode's own database **read-only**, copies one row per session, agent and model into the book's SQLite store, and answers from there.

| It reads | It writes |
|---|---|
| `~/.local/share/opencode/opencode.db` (`opencode db path` prints yours) | `~/.local/share/opencode-dashboard/cost.db` |
| or one `opencode export <id>` file, with `--export` | `~/Documents/opencode-weekly/<week>.md` (report) |
| | `cost-log.csv` in the current folder (log) |

## Today

```bash
chapters/09-cost-dashboard/cost-dash today
```

```
opencode cost dashboard | 2026-W19 Wednesday
─────────────────────────────────────────────
today's run-rate:    $1.00  (warning at $0.80, cutoff $1.50)
session count:       3
top model:           opencode-go/kimi-k2.7-code  ($0.74, 75% of today)
top provider:        opencode-go  ($1.00, 100% of today)
token split:         input 61% / output 20% / cache read 19%
this week so far:    $1.03  (target $7.00, on pace)
```

That's a run on the made-up store in `tests/fixtures`; yours shows your sessions. Dollars are what opencode recorded on each message, summed. `cost-dash` never prices anything, so a local Ollama session shows `$0.00`. The token split counts tokens, not dollars. To reproduce the sample:

```bash
rm -f /tmp/sample.db
python3 -c 'import sqlite3,sys; sqlite3.connect(sys.argv[1]).executescript(open(sys.argv[2]).read())' /tmp/sample.db tests/fixtures/opencode-synthetic.sql
chapters/09-cost-dashboard/cost-dash today --opencode-db /tmp/sample.db --db /tmp/sample-cost.db --date 2026-05-06
```

## The other commands

| Command | What you get |
|---|---|
| `cost-dash log --project <name> [--session ID \| --last]` | the book's `cost-log.csv` rows, one per agent and model, plus the session's duration |
| `cost-dash report [--week 2026-W19]` | the Sunday Markdown report: totals by model, agent, provider and task class, and the days over $0.80 |
| `cost-dash tag <session> refactor` | fills `task_class` (`refactor`, `greenfield` or `debug`) so the report can split by it |
| `cost-dash alert [--cutoff]` | prints a warning and exits 1 at $0.80 today; with `--cutoff`, writes the cooldown file at $1.50 |
| `cost-dash reset --reason "I know what I'm doing"` | deletes the cooldown file and appends your reason to `resets.log` |

Every command takes `--warn`, `--cutoff-at`, `--daily-target` and `--week-target`; the defaults are the book's $0.80, $1.50, $1.00 and $7.00. `--opencode-db` and `--db` point at other files.

The report flags a day over the warning and a session far above the week's average, and writes `cause: unknown, you must observe this` under each one. The book's example blames "4 redesign rounds"; only you know that, so the line is yours to fill in.

## The alert, the cutoff, and the Sunday report

```cron
*/5 * * * * $HOME/your-project/tools/cost-dash alert --cutoff >> $HOME/.local/share/opencode-dashboard/alert.log 2>&1
0 21 * * 0  $HOME/your-project/tools/cost-dash report
```

`crontab -e` and paste both lines. Warnings land in `alert.log`. For a macOS notification as well, end the first line with `|| osascript -e 'display notification "opencode spend over $0.80 today"'`.

opencode itself never looks at the cooldown file. The check lives in this shell function. Add it to `~/.zshrc` or `~/.bashrc`, and every `opencode` you type refuses to start while the cutoff is set:

```bash
opencode() {
  [ -f ~/.local/share/opencode-dashboard/cooldown ] && { cat ~/.local/share/opencode-dashboard/cooldown >&2; return 1; }
  command opencode "$@"
}
```

Project #8 works when `cost-dash today` shows today's sessions, `cost-dash alert` exits 1 on a day past $0.80, and `~/Documents/opencode-weekly/` holds a report for this week.

## On your own project

The book keeps it at `<your project>/tools/cost-dash`:

```bash
cp chapters/09-cost-dashboard/cost-dash ~/your-project/tools/
```

It reads every session on your machine, whichever project it ran in, so one copy covers all of them. If opencode ever moves its store, point `--opencode-db` at the new file, or feed it `opencode export <id> > s.json` and `--export s.json`.
