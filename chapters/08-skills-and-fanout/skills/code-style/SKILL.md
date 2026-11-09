---
name: code-style
# ch8, body written here (book prints only the tagline). add your rules under Conventions before relying on it.
description: Apply this project's code-style conventions across all edits
license: MIT
compatibility: opencode
---

## Conventions

- The formatter is whatever `package.json` runs (Biome, Prettier, or the `format` script).
  Run it on every file you touched before you report done. Never hand-format.
- Imports in three groups, a blank line between: packages, then `@/` aliases, then relative paths.
- File names are kebab-case (`user-repository.ts`). React component files are PascalCase.
- Exported functions and constants are camelCase; types and components are PascalCase.
- Keep a function in its current file until the file passes about 300 lines or does two jobs.
  Then split by job, not by size.

## When the agent invokes this skill

Call `skill({ name: "code-style" })` before the first edit of a session, and again before
creating a new file.

## Anti-patterns

- Reformatting lines the task did not touch. It hides the real change in the diff.
- A new formatter or lint config the project does not already have.
- `utils.ts` or `helpers.ts` as the home for a function that belongs to one feature.
