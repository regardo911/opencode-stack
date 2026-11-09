---
name: typescript
# Chapter 8, the TypeScript SKILL.md as printed. Copy this folder to ~/.config/opencode/skills/typescript/
description: Write TypeScript that matches this project's strict-mode + utility-type conventions
license: MIT
compatibility: opencode
---

## Conventions

- Strict mode: `"strict": true` in `tsconfig.json`. No `any` outside boundaries.
- Use `unknown` for boundary inputs, narrow before use.
- Prefer utility types (`Pick<T, K>`, `Omit<T, K>`, `Record<K, V>`) over hand-rolled.
- Generic constraints with `extends`, not bare type parameters.
- One named export per file unless the file is a barrel re-export.

## When the agent invokes this skill

The agent should call `skill({ name: "typescript" })` before writing any
TypeScript file or modifying any function signature. After loading, apply
the conventions above to whatever the agent is about to write.

## Anti-patterns

- Hand-rolled interfaces that duplicate utility-type results.
- `any` in function signatures (must be `unknown` then narrowed).
- Default exports (use named exports).
