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
