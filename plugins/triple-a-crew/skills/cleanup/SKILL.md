---
name: cleanup
description: Remove the noise implementation leaves behind - redundant comments, commented-out code, debug logs, and try-catch blocks that only log and rethrow - from the files changed in the current work, without changing behavior. Use after an implementation is done or approved and before review or merge, or when the user asks to clean up, tidy or de-noise the code that was just changed. Keeps API docs, why-comments, operational logs and error handling that does real work.
---

# Cleanup

Make the changed code lean and production-ready by removing noise. Never change behavior, naming or
structure.

## 1. Scope

Only the files changed in the current work:

- the files the user names, or the file sets of the work item's tasks (`.crew/work/<id>/plan.md`);
- otherwise the working-tree diff against the base branch (`git diff --name-only <base>...` plus uncommitted
  changes).

Never sweep the whole repository unless the user asks. Read the project's logging and comment rules first
(the `conventions` files in `.crew/profile.md`, `CLAUDE.md`); they win over the defaults below.

## 2. Comments

- **Remove:** comments that restate the code ("fetches the user by id" above `getUserById`), commented-out
  code, step-by-step narration, and TODO or FIXME notes that only mattered while implementing.
- **Keep:** API docs (JSDoc, docstrings, TypeDoc) on public functions; comments that explain *why* (a business
  rule, a workaround, a non-obvious constraint); short notes on genuinely tricky logic.

## 3. Logs

- **Remove:** debug output added during development (`console.log`, `print`, `logger.debug` used as
  printf debugging) and repetitive logs inside loops or hot paths.
- **Keep:** error and warning logs, and one clear info log per meaningful boundary ("sync started",
  "request failed after retries"). When unsure, keep one clear log rather than many small ones.

## 4. Try-catch

- **Remove:** a try-catch that only rethrows, or catches, logs and rethrows without adding anything; a
  try-catch around one statement that changes neither control flow nor the value returned. Let the error
  reach a layer that can handle it.
- **Keep:** a try-catch that translates errors into domain or user-facing errors; implements retries,
  fallbacks or an alternative path; stops one failing item from aborting a batch; or releases resources in
  `finally` when correctness depends on it.
- A borderline case (only logs and rethrows): remove it, and say in the summary that the caller or a global
  handler now owns that error.

## 5. Prove nothing changed

Run the project's `verify` commands from `.crew/profile.md` (or its test command) after editing. If anything
fails, your edit changed behavior: undo that edit.

## 6. Report

List per file what you removed (counts of comment blocks, log lines and try-catch blocks) and anything you
deliberately kept and why, then the verify results.
