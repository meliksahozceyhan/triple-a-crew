# Agent-teams mode for the organizer

**Size:** L · **Ticket:** none (roadmap, W2 of the v1 handoff) · **Opened:** 2026-10-19

## What
Claude Code has an experimental "agent teams" feature: instead of one-shot subagents, the main session leads
a team of teammates that can message each other and share a task list. Plan an optional team mode for the
organizer: when teams are enabled, employees become teammates; otherwise subagent mode stays exactly as it is.
The files in `.crew/work/` remain the source of truth in both modes (DESIGN "Two channel modes").

## Why
In subagent mode a blocked employee stops, and the organizer resumes it with `SendMessage`: one round trip per
question, and parallel employees cannot talk to each other. Team mode could make long L items faster and let
the reviewer question the engineer directly.

## Done when
- [ ] A decision, from the research, on whether team mode is worth building now or should wait.
- [ ] If built: the organizer detects team mode, staffs teammates, keeps `board.md` and status files current,
      and falls back to subagent mode when teams are off; an eval or a documented manual test covers it.
- [ ] DESIGN's "Two channel modes" table matches what the feature really does today.

## Constraints
- Conventions (profile): `docs/DESIGN.md` (Communication protocol), README "Conventions for new skills".
- The design must keep working fully in subagent mode.
- One writer per file; the writer never reviews; parallel writers only on disjoint file sets.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| Teams off (the default) | yes | subagent mode unchanged |
| Non-interactive or eval runs, where teams may be unavailable | yes | T1 research; fallback |
| Session resumed: teammates gone | yes | files on disk are the source of truth |
| Two sources of truth (built-in task list and `board.md`) | yes | plan picks one owner |
| Teammates editing the same files | yes | disjoint file sets still required |
| Cost: each teammate is a full session | yes | staffing rule on when to use teams |
| Feature changes or is removed (experimental) | yes | isolate team mode in one reference file |
