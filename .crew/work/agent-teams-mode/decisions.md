# Decisions

- **2026-10-19 Opt-in team mode for every role, writers included (your choice; the organizer had
  recommended waiting, then read-only roles only).** Gain: live questions, and a reviewer can question the
  engineer directly. Because a named teammate gets no worktree, writers share the working directory, so the
  organizer adds guardrails: writers at the same time only on disjoint file sets, otherwise one at a time;
  teammates never commit; verify only after all writers finish; code changes only through tasks the organizer
  assigns. The research risks stay true: much higher token use, no `/resume` for teammates, experimental
  status, no eval coverage (a manual test replaces the eval). Rejected: read-only roles only (the
  organizer's revised proposal); waiting.
- **2026-10-19 Spawn employees without a `name` outside team mode.** With
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set globally, a named `Agent` call launches a teammate; unnamed
  calls keep subagent mode predictable.
- **2026-10-19 Don't use the built-in task list.** It lives in `~/.claude/tasks/`, outside the repo, and lets
  teammates self-claim, which could hand a reviewer its own work. The board stays the only task list.
- **2026-10-19 Team-mode rules live in `skills/work/teams.md`,** loaded only when team mode is detected, so
  the organizer's SKILL.md stays short and the experimental part is easy to change or remove.
- **2026-10-19 Plan approved by the user with writers as teammates.**
- **2026-10-19 T2 done by the organizer, with the README roadmap row.** The table had to be checked against
  the docs, and the engineer has no WebFetch, so the organizer fetched the agent-teams and subagent-names
  pages and rewrote DESIGN "Two channel modes" with a sourced row each for start, employees, working
  directory, questions, task list, hooks and limits. The README roadmap gained a done `v2` row; DESIGN's v2
  phase says the same. T7 reviews this with the rest of the diff. Rejected: an engineer on T2 (a doc check it
  cannot do), a researcher plus an engineer (two hand-offs for one table).
- **2026-10-19 The docs already answer part of T3.** A plugin agent type can be a teammate; the model the
  spawn prompt names wins over the definition's; `tools` and the body apply; `skills` does not (so the
  test-engineer's `test-harden` preload won't happen as a teammate, and its fallback read is what covers
  it); a named call with `isolation` stays a subagent; `-p`, SDK and eval runs never spawn teammates. Still
  open for the live test: `maxTurns`, whether SubagentStart/SubagentStop fire for teammates, the plugin
  agents in practice, detection from a skill, and the desktop app. The test enables teams only in a scratch
  folder's `.claude/settings.local.json`, so other sessions keep subagent mode.
