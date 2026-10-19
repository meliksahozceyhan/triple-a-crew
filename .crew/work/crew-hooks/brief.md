# Three crew hooks: open-items summary, protocol injection, status-file gate

**Size:** L · **Ticket:** none (roadmap, W2 of the v1 handoff) · **Opened:** 2026-10-19

## What
Tier 3 of the design: plugin hooks that make the crew faster and its protocol enforceable. A hook is a
command Claude Code runs on an event (session start, a subagent starting or stopping) and whose output can
add context or block the event. Three are planned (DESIGN "Enforcement through hooks"):

1. **SessionStart:** a one-paragraph summary of open work items from `.crew/work/index.md`.
2. **SubagentStart:** inject the status-file protocol and the employee's status-file path into crew
   employees.
3. **SubagentStop:** block a crew employee from finishing while its status file is missing, not in a final
   state (`done`, `blocked`, `failed`), or lacks the final report sections.

## Why
The protocol relies on employees following their agent file. In this session's work item the reviewer did
write its status file, but nothing enforces it, and the organizer only notices a missing file after the
employee is gone. A session-start summary also saves the user from asking "where are we?".

## Done when
- [ ] Hooks ship in `plugins/triple-a-crew/hooks/` with scripts that run on macOS and Linux.
- [ ] They are silent and fast in projects without `.crew/`, and never touch non-crew agents.
- [ ] With hooks disabled, nothing breaks (tier 3 rule).
- [ ] Tests or evals show each hook doing its job; `claude plugin validate .` passes.
- [ ] READMEs, DESIGN (the tier diagram, "Enforcement through hooks", Verified mechanics) updated.

## Constraints
- Conventions (profile): README "Conventions for new skills", `docs/DESIGN.md` (Communication protocol,
  Verified mechanics).
- The plugin is installed at user scope, so hooks run in every project the user opens.
- Claude chat ignores hooks; Cursor may differ (see `cursor-check`).

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| Project without `.crew/` (most projects) | yes | every hook exits 0 with no output |
| `index.md` with many open items | yes | summary capped (a few lines) |
| Built-in agents (Explore, general-purpose) and other plugins' agents | yes | match only `triple-a-crew:*` agents |
| An employee started by hand, without a brief or status file | yes | SubagentStop must not block forever |
| SubagentStop blocks, the employee retries, blocked again (loop) | yes | loop guard from the hook API |
| How a hook finds an employee's status file | yes | T1 research |
| `node` not installed (Claude Code is a native binary) | yes | T1 research decides the script language |
| Windows | no for now | findings |
| Employee in its own worktree | yes | status file is an absolute path in the main checkout |
| Hooks disabled (`disableAllHooks`) | yes | nothing depends on them |
| Eval runs and hooks | yes | T1 research |
