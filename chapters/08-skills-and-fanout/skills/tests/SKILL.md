---
name: tests
# ch8 tagline, our body. put your test runner and folder names in.
description: Write tests that match this project's runner, structure, and fixture conventions
license: MIT
compatibility: opencode
---

## Conventions

- The runner is the one `package.json` names in its `test` script. Use its assertion style
  (`expect(...)` for Vitest and Jest). Never add a second runner.
- Unit tests sit next to the file: `user-repository.ts` → `user-repository.test.ts`.
- Integration tests that touch the database or HTTP live in `tests/integration/`.
- Fixtures are small builders in `tests/fixtures/` (`makeUser({ email })`), not shared JSON files.
- Mock the network and the clock. Do not mock the module under test.

## When the agent invokes this skill

Call `skill({ name: "tests" })` before writing or changing a test, and after any change to a
function's signature. Run the `test` script and report the pass and fail counts.

## Anti-patterns

- A test that asserts a function was called instead of what it returned or wrote.
- Snapshot tests for logic.
- Deleting or skipping a failing test to make the run green.
