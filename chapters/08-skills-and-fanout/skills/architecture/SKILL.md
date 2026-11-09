---
name: architecture
# ch8: the book gives the job and tagline, no body. this body is ours. swap in your real folder map.
description: Place new files in the right directory and respect this project's layering rules
license: MIT
compatibility: opencode
---

## Folder map

- `app/` routes and pages. No database calls here.
- `app/api/` HTTP handlers. Parse input, call the data layer, shape the response.
- `data/` the data layer: every query and write, one `<thing>-repository.ts` per model.
- `lib/` code with no I/O that two or more features share.
- `prisma/migrations/` (or your migrations folder) new migrations only, never edits to old ones.

## Layering rules

- Imports go one way: `app/` → `app/api/` → `data/` → `lib/`. Never back up the chain.
- A handler never builds SQL or calls the ORM. It calls a repository function.
- A new endpoint gets a handler in `app/api/<name>/route.ts` and, if it reads or writes data,
  a function in the matching repository.

## When the agent invokes this skill

Call `skill({ name: "architecture" })` before creating any file, and before moving code between files.

## Anti-patterns

- A query inside a route handler "just this once".
- A new top-level folder the map above does not list.
- Two repositories for the same model.
