# Decisions

- **2026-11-13 Approval phase skipped.** The user saw the three-track plan and said to create the tasks and
  start implementing them, in parallel where possible. Every change still reaches `main` only through a pull
  request the user merges.
- **2026-11-13 Engineers work in this branch's worktree by absolute path, not in worktrees of their own.** A
  probe (`organizer-rules` P1) showed that an `isolation: "worktree"` employee is refused when it writes its
  status file in the main checkout, and the stop hook then blocks it three times. The main checkout stays on
  `main`, so running employees keep the definitions the session loaded. Rejected: `isolation: "worktree"`
  (the status-file protocol cannot be followed); editing the main checkout (it would change the running
  plugin).
- **2026-11-13 #32: a strict format, no tolerance, no check for old times.** `updated` must look like
  `2026-01-31T14:05:00Z` and must not be later than `date -u`, compared as strings; both come from the same
  clock. Rejected: a write-time check on Write and Edit, as a comment on #32 suggested (a hook on every write
  for a case the stop check already catches); comparing with the file's modification time (no portable way in
  POSIX sh); a staleness limit (an employee answering a follow-up has an old file).
- **2026-11-13 B: the guard acts on crew employees only.** It tells them from the main session by
  `agent_type`. Rejected: guarding the main session, which would also have caught the organizer's own `cd`
  (four recorded cases): a public plugin must not refuse commands in the user's session.
- **2026-11-13 B: the exception reads the brief; the valve is "send it again".** A command the brief lists
  runs. When the brief cannot be read, only the documented form `cd "<folder>" && <command>` runs. A refused
  command sent again unchanged runs, so the hook can never trap an employee on a false match. Rejected:
  refusing `$(...)` (the rule does not name it); a cap of three as in the stop hook (one repeat is enough to
  make the rule seen).
- **2026-11-13 C: warn the organizer through PreToolUse on `Agent`, once per change.** The hook adds context
  and never refuses. Checksums, not modification times: a checkout touches times. Rejected: refusing the
  spawn (no event fires on `/reload-plugins`, so the hook would refuse forever after a reload); a warning in
  `SubagentStart` (it reaches the employee, after the organizer has already staffed it).
- **2026-11-13 C covers agent files only.** The recorded cases are agent files; the organizer's reference
  files are read on demand. The brief's C.1 and the issue draft say "agent file".
- **2026-11-13 Each new hook has its own test file; the organizer wires `hooks.json` and the runner.** That
  makes T3, T4 and T5 disjoint, so they run in parallel.
