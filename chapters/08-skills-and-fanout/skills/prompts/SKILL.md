---
name: prompts
# ch8 names this skill and stops there. tagline + body are ours; the 3 prompts are the book's. add the ones your team retypes.
description: Reusable prompts for tasks this team repeats, such as a PR security review
license: MIT
compatibility: opencode
---

## Prompts

### Review this PR for security issues
Read the diff. List every place that takes user input, touches auth or a session, builds a
query, or reads a secret. For each one: the file and line, the risk in one sentence, and the fix.
If you find nothing, say which of those four you checked.

### Convert this Python script to a Cloud Function
Keep the script's inputs and outputs the same. Move configuration to environment variables.
Show the new entry point, the dependency list, and the one command that deploys it.

### Extract a reusable hook from this component
Find the state and effects that do one job. Move them to `use-<job>.ts` with a typed return value.
The component keeps its props and its rendered output.

## When the agent invokes this skill

Call `skill({ name: "prompts" })` when the task names one of the headings above.

## Anti-patterns

- Running a prompt from this list on a task it does not name.
