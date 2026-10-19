# A `retro` skill: learn from a closed work item

**Size:** M · **Ticket:** none (roadmap, W2 of the v1 handoff) · **Opened:** 2026-10-19

## What
A skill that runs a short retrospective on a work item: compares the plan with what happened (missed
acceptance checks, escalations, blocked questions, reviewer must-fixes, findings, the user's corrections),
writes `.crew/work/<id>/retro.md`, and routes each lesson to where it will be used: the project's profile
notes or convention files (with the user's OK), an issue, or nowhere. The organizer runs it at close (step
10, which today says "Write the handoff/retro" in DESIGN but has no retro), and the user can run it by hand.

## Why
Lessons from a work item now die with its ignored working state (`board.md`, `team/`). The handoff skill
carries lessons to the next session of the same effort, but nothing feeds them back into the project, and
nothing notices the same problem recurring across work items.

## Done when
- [ ] `plugins/triple-a-crew/skills/retro/SKILL.md` (under ~150 lines) and the `retro.md` format in
      `skills/work/formats.md`.
- [ ] The organizer's close step runs it for M and L items.
- [ ] Eval cases: a trigger case with a baseline that shows a gain, a no-trigger near miss, and a case where
      an earlier retro reported the same problem.
- [ ] READMEs and DESIGN updated; `claude plugin validate .` passes.

## Constraints
- Conventions (profile): README "Conventions for new skills" (earn the place, portable frontmatter, short
  SKILL.md), `docs/DESIGN.md` (State on disk, Lifecycle).
- Profile notes, `organizer`, `models` and `issue_tracker` are user-owned (`onboard` profile-format): retro
  proposes edits and asks; it never writes them on its own.
- Publishing an issue goes through `file-issue` and its confirmation rules.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| Abandoned item (user said "just do it") | yes | short retro: why it was abandoned, if known |
| No `team/` files (the organizer did everything) | yes | reads board, decisions, findings only |
| Same problem in an earlier retro | yes | the skill reads earlier `retro.md` files and calls out repeats |
| Lesson about the crew itself, not the project | yes | listed for the user as a plugin finding, filed only with OK |
| Lesson that would change a user-owned profile field | yes | proposed, never written without asking |
| Secrets or customer data in status files | yes | redacted, as in `file-issue` |
| Very large work item (20+ tasks) | yes | counts plus the top lessons, not a task-by-task log |
| Retro asked on a session with no work item | no | out of scope; `handoff` covers sessions |
