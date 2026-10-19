# Decisions

- **2026-10-19 Scripts in POSIX `sh`, `jq` optional.** The docs guarantee neither `node` nor `jq`; `node` here
  comes from nvm, which a GUI-launched app may not have on PATH. Rejected: `node` (fails silently for some
  users), `python3` (same problem).
- **2026-10-19 SubagentStart injects the protocol only.** Its input has no prompt and the transcript may not
  exist yet, so it cannot know the status-file path; the brief already names it. Rejected: deriving the path
  from a scan at start time (races with parallel employees).
- **2026-10-19 SubagentStop never blocks when it cannot resolve the status file.** A parsing failure must
  never trap an employee; the hook is a strong nudge (the docs cap consecutive blocks), not a guarantee.
  Rejected: blocking on "no status file found" (would trap employees started by hand).
- **2026-10-19 The report check reads the final message, not the status file.** The protocol puts the final
  report in the employee's reply; DESIGN says otherwise and gets corrected in T8.
- **2026-10-19 Spike before building.** The subagent payload fields were read from summarized docs; a
  ten-minute dump of real stdin settles them before three scripts depend on them.
- **2026-10-19 Match `^triple-a-crew:[a-z-]+$`.** Covers roles added later (`verifier`, `test-engineer`)
  without editing hooks.json. Rejected: listing roles (silently misses new ones).
- **2026-10-19 Plan approved by the user as written.**
