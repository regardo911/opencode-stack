# Chapter 6: the orchestrator and the fixer

One `opencode.json`, four agents. Two names you'll see a lot:

- **orchestrator**: the agent that reads your code and writes a numbered plan. It asks before it touches anything.
- **fixer**: the agent that carries out the plan. It edits and writes without asking; shell commands still ask.

Both pairs live in [`opencode.ch06.jsonc`](opencode.ch06.jsonc): `orchestrator` + `fixer` (Project #3), and `orchestrator-glm` + `fixer-deepseek` (Project #4, the A/B). Only `orchestrator` and `fixer` set permissions; the A/B pair uses opencode's defaults.

The models come from **OpenCode Go**, the opencode team's $10-a-month plan of open-weight models (the book's price; check opencode.ai for today's). You subscribe in the browser, then type `/connect` in the opencode TUI, pick OpenCode Go and paste the key.

## 1. Put the config in your project

```bash
cp chapters/06-routing/opencode.ch06.jsonc ~/your-project/opencode.json
cd ~/your-project
opencode debug agent orchestrator
```

You should see JSON that names the agent and its model:

```
    "providerID": "opencode-go",
    "modelID": "kimi-k2.7-code"
```

If you get `Configuration is invalid`, opencode prints the key it did not like. If you already have an `opencode.json`, paste the four entries under your existing `"agent"` key instead of copying over it.

**Before your first real run, check the model ids.** Go's list changes every few weeks, and these four were the nearest matches on 2026-11-09 to the models the book used (the file's comments name the book's ids). Open `opencode`, type `/models`, and if a model in the file is not in the list, change that line. That is the whole edit; the agent names and permissions stay.

## 2. Run Project #3 on one real file

Pick a file of 150+ lines that does two jobs. Then:

```bash
opencode --agent orchestrator
```

```
Read /api/users.ts. Propose a split that separates the data layer from the API layer. Output the plan as a numbered list of sub-tasks with the files and changes per task.
```

Read the plan. When it is right, quit and start the fixer in the same folder:

```bash
opencode --agent fixer
```

```
Execute this plan, in order, one sub-task at a time. Pause between sub-tasks for me to verify each diff.
<paste the plan>
```

The orchestrator hands back a plan; the fixer hands back edited files. Both bill your Go plan.

## 3. Write the cost rows

Each `opencode` run above is a session. Log both of them, one row per agent:

```bash
chapters/09-cost-dashboard/cost-dash log --project project-03-routing-k26-qwen --session <orchestrator session id> --csv ~/your-project/cost-log.csv
chapters/09-cost-dashboard/cost-dash log --project project-03-routing-k26-qwen --last --csv ~/your-project/cost-log.csv
```

`opencode session list` shows the ids. `--last` takes the session that finished most recently. Each call prints the rows it appended, then two lines like these (from a local test session):

```
duration: 5m 55s (first message to last reply)
diff quality: unknown, you must observe this
```

The duration is read off the message times. Diff quality is yours to judge: read the diff.

## 4. The A/B

`git stash` or `git checkout` the file back, then repeat steps 2 and 3 with `--agent orchestrator-glm` and `--agent fixer-deepseek` and `--project project-04-routing-glm-deepseek`. Now `cost-log.csv` has four rows from this chapter.

Write your winner per axis next to them:

| Axis | Read it from | Project #3 | Project #4 |
|---|---|---|---|
| Cost | `cost_usd`, summed per project | | |
| Wall-clock | the `duration:` lines | | |
| Diff quality | your own read of the two diffs | | |

**Done when:** `opencode debug config` lists 4 agents, `cost-log.csv` has 4 new rows, and the table above has a winner in every row.

## On your own project

Copy it to the root of any repo where you want the pair. If a teammate should get the same agents, commit it; if only you should, put the `"agent"` block in `~/.config/opencode/opencode.json` instead and every project on your machine gets it.

A `cost_usd` of `0.0000` on a Go row means opencode recorded zero. `cost-dash` shows that number as is.
