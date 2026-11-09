# Chapter 8: five skills and the fan-out

## Project #6: the skills

`skills/` holds the five the book names. `typescript` is the book's file as printed. The book describes the other four in a paragraph each and prints no body, so their bodies are written to match (each file's header says so). They point the agent at your `package.json` scripts and folders. Swap in your own folder map and conventions and they get sharper.

```bash
mkdir -p ~/.config/opencode/skills
cp -R chapters/08-skills-and-fanout/skills/* ~/.config/opencode/skills/
opencode debug skill | grep '"name"'
```

You should see all five names, in any order, plus any skills you already had: `architecture`, `code-style`, `prompts`, `tests`, `typescript`.

Use `<repo>/.opencode/skills/` instead of the global folder when a skill only fits one project.

**Measure them.** The book's test is the same prompt twice. Run A with skills off, by adding this to your project's `opencode.json`:

```json
"permission": { "skill": "deny" }
```

Run your question, then `cost-dash log --project project-06-skills-test-no-skills --last`. Remove the line (or set it to `"allow"`), start a fresh session, run the same question, then `cost-dash log --project project-06-skills-test-with-skills --last`. Your multiplier is run A's `input_tokens` divided by run B's. The book says real codebases land between 5× and 50×.

## Project #7: the fan-out

[`worktree-fanout.sh`](worktree-fanout.sh) is the book's script with the chapter 8 fixes from [BOOK-FIXES.md](../../BOOK-FIXES.md). It cuts six git worktrees from your current commit, runs the same prompt through your `fixer` agent in each one, commits what each agent changed, and prints six diffs.

![The seven steps of worktree-fanout.sh: record the start commit, make 6 worktrees on branches fanout/1 to fanout/6, run the fixer in each, commit each agent's changes, print 6 diffs against the start commit, merge the one you pick, remove the other 5 with --force. The commit step and the --force step are highlighted as the two the printed script missed.](../../docs/images/fanout.png)

Run it in your own project, never in this clone. It creates `../<your-repo>-fan-1` to `-fan-6` next to your repo.

```bash
cp chapters/08-skills-and-fanout/worktree-fanout.sh ~/your-project/tools/
cd ~/your-project
tools/worktree-fanout.sh "Refactor /api/users.ts to extract the data layer into /data/users-repository.ts. Preserve the public API. Apply the architecture and code-style skills."
```

Six fixer runs bill your Go plan. `N=2` runs two instead of six; `AGENT=fixer-deepseek` uses the other fixer.

Two things decide whether it works:

- **The agent must exist inside each worktree.** A worktree is a fresh checkout of your last commit. If `fixer` lives in an `opencode.json` you never committed, the worktrees can't see it. Commit the file, or keep the agent in `~/.config/opencode/opencode.json`.
- **`opencode run` can't ask you anything.** On opencode 1.19.5 an `ask` permission in a run like this is rejected, not held open (the log says `auto-rejecting`), so the fixer's `bash: "ask"` means the agent edits files but runs no shell commands. Leave it that way. If a refactor needs the tests run, run them yourself in the winning worktree.

Pick the winner and clean up. Each agent's log is in `../fan-<N>.log`.

```bash
git merge fanout/3
for i in 1 2 4 5 6; do
  git worktree remove --force "../your-repo-fan-$i"
  git branch -D "fanout/$i"
done
git worktree remove --force ../your-repo-fan-3
```

Check it: `git log` shows the winning agent's commit on your branch, and `git worktree list` shows only your repo. Then log the cost: `cost-dash log --project project-07-fanout --session <id>` once per worktree session (`opencode session list` shows all six).
