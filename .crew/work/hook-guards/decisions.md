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
- **2026-11-13 T9 review: changes requested, one must-fix.** (M1) The resend valve remembered one refused
  command per agent and forgot it on any allowed call, so two refused commands sent together could never both
  run, although the message said a resend works. The guard now keeps each refused command on its own line,
  the newest 20, and an allowed call leaves them alone. Should-fix, all fixed: (S1) an agent that is only
  named like a teammate is guarded only when its brief can be read and names a status file; (S2) team mode
  was not probed for PreToolUse, and DESIGN says so; (S3) the definition note says "unless /reload-plugins
  has run since"; (S4) one more probe run showed that the note reaches the organizer in the exact form the
  script prints, with no permission decision, and the call still runs; (S5) three statements in the docs did
  not match the scripts. Nits fixed: a lone `&` counts as a chain; a test ties the guard's role list to
  `hooks.json`; the stamp update touches one role's line; a tab in a status value no longer breaks the stop
  hook's output; the missing-`updated` test asserts the command text. A command over 20,000 characters is
  allowed without analysis, which answers the reviewer's question about slow awk. Each script's own engineer
  made its fixes (rung 1 of the ladder: sent back once).
- **2026-11-13 Not changed after T9:** quoted chains pass by design (N2), and three plain commands are refused
  once and run on the resend (N3: a comment line above a command, a heredoc with an odd number of quotes, a
  brief that lists a pipe inside a Markdown table). The guard is a reminder with a valve, not a wall.
- **2026-11-13 T9b recheck: changes requested, one must-fix.** (R1) The rewritten valve read, rewrote and
  renamed one state file with no lock, so two overlapping hook runs could lose a refusal. Each refusal is
  now its own empty marker file, created to remember and removed on the resend, so there is nothing to
  rewrite and no cap of 20. Nits fixed: a length limit before the no-jq reader, `LC_ALL=C` for the control
  character filter, one overstated comment. Left on purpose and documented: (R2) a refused command that is
  never resent stays remembered until pruned, so the same command later runs once without a refusal; (R4)
  an unquoted `&` in shell arithmetic is refused once. Not probed: whether Claude Code overlaps the hook runs
  of two Bash calls; the fix is right either way. The fix is size S (one script and its tests), so per step 8
  it is made and verify is rerun, with no third reviewer.
- **2026-11-13 The definition hook prints no permission decision, on purpose.** A decision of `allow` would
  approve every Agent call in the user's session; the probe showed the note is delivered without one.
