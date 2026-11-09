# Chapter 10: the invoice tracker and your own skill

## Project #9

Use the chapter 6 pair. Hand this to `opencode --agent orchestrator`:

```
Plan a Next.js client invoice tracker. Auth via NextAuth (email-only).
Database via Prisma + SQLite for local; design the schema with `Client`,
`Invoice`, `LineItem` models. One paid endpoint at POST /api/invoices/charge
that creates a Stripe charge in test mode against a stored card. Deploy
to Vercel. Output the plan as 8-10 sub-tasks the fixer agent can execute
in order.
```

When the plan is right, hand it to `opencode --agent fixer`:

```
Execute the plan, one sub-task at a time. Pause between sub-tasks for me
to verify each diff. Use the typescript, code-style, architecture, and
tests skills throughout.
```

Then `cost-dash log --project project-09-invoice-tracker` for each session.

## Project #10

[`skill-template/SKILL.md`](skill-template/SKILL.md) is the book's fill-in template with the `stripe-payments` frontmatter already on it. Write your own skill in it, then:

```bash
mkdir -p ~/.config/opencode/skills/stripe-payments
cp chapters/10-ship-the-last-two/skill-template/SKILL.md ~/.config/opencode/skills/stripe-payments/
opencode debug skill | grep '"name": "stripe-payments"'
```

A skill about something else needs a new folder. Use the same word for the folder and `name:`, as opencode's docs ask.

The book sends the PR to `alvinunreal/oh-my-opencode-slim` and says to look at its `skills/` folder. On 2026-11-09 that repo had no top-level `skills/`; its skills sat under `.agents/skills/`. Look at where the existing ones live before you open the PR.

## The ten-project table

Fill it from your `cost-log.csv`: sum `cost_usd` per project.

| # | Project | Public URL | Models used | Cost (USD) |
|---|---------|------------|-------------|------------|
| 1 | "I shipped this with OpenCode" static site | | | |
| 2 | Bookmarks tracker (CRUD + 7-day cost log) | | | |
| 3 | K2.6 + Qwen routing config (refactor) | | | |
| 4 | GLM + DeepSeek routing config (A/B) | | | |
| 5 | Self-hosted local stack (zero outbound) | | | |
| 6 | 5 skills + 2 plugins (token-reduction test) | | | |
| 7 | worktree-fanout.sh (one merged refactor) | | | |
| 8 | Cost dashboard (SQLite + alerts + weekly) | | | |
| 9 | Client invoice tracker (auth + DB + Stripe) | | | |
| 10 | Published skill (PR to oh-my-opencode-slim) | | | |
