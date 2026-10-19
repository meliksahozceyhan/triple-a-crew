# Decisions

- **2026-10-19 One work item and one PR for all eleven issues.** They touch overlapping files (SKILL.md,
  protocol.md, the agent files, the eval cases), so separate PRs would conflict. Commits are grouped by area.
  Rejected: a PR per issue.
- **2026-10-19 #15 guard checks only for an empty folder.** The docs say the scaffold script starts in an
  empty workspace and receives no harness variable (T1). Rejected: also checking `$HOME/cwd` (the layout is
  unconfirmed and costs an eval run with `--keep-temp` to settle).
- **2026-10-19 #17 and #12 graders use `regex` on the trace, not `llm` judges.** No grader can scope to the
  main agent, but main-agent rows carry `"parent_tool_use_id":null`; and a trace judge sees only the first
  and last 12 messages (T1). Rejected: an `llm` trace judge (misses the middle of long runs).
- **2026-10-19 #19 at most one automatic recheck round.** A recheck that itself requests changes goes back to
  the organizer to decide, so cost stays bounded. Rejected: rechecking until clean (unbounded opus cost).
- **2026-10-19 #14: write-as-you-go first, then `maxTurns` 40 to 60 for the reviewer only.** The researcher
  and verifier never ran out. Rejected: 80 like the writers (higher worst-case cost for a read-only role).
- **2026-10-19 No worktrees for T2, T3 and T4.** Their file sets are disjoint and none runs the others'
  checks, as in earlier items. Rejected: worktrees (merge work with no benefit).
- **2026-10-19 Convention check (size L, README "Conventions for new skills").** "Short SKILL.md": T2 keeps it
  at most 160 lines and moves detail into reference files. "One case per key rule": #13, #17, #18, #22 and
  #7 get graders (T5); #19 gets none, because a case would need a review that requests changes and a
  second round (several dollars per run); its text change is checked by review and in real items.
- **2026-10-19 Investigation was a researcher task (T1), run before the go-ahead.**
- **2026-10-19 Plan approved by the user as written.** Correction at staffing: 13 fixtures, not 22, and only
  one of them in `file-issue`, so T11 reruns that one case instead of the whole `file-issue` suite.
- **2026-10-19 T5 split into T5a and T5b, in parallel.** T5a: graders in `medium-fix-end-to-end` (#17, #12,
  #21), `starts-work-item-on-large-request` (#18) and `test-engineer-keeps-failing-test` (#22). T5b: #7, a new
  size-L convention-check case and the noise rule in `verify-staffs-verifier`. Their case folders are disjoint.
  Rejected: one test-engineer for both (twice as long, and a long task risks its turn budget).
- **2026-10-19 T7, T8 and T9 run together.** All three are read-only and no writer is running, so the
  reviewers don't need to wait for the verifier's result. Rejected: verify first (a few minutes saved by
  nothing).
- **2026-10-19 T9 review of the evals: changes requested, all applied by the organizer.** F2 (must-fix): the
  placeholder-time grader passed invented times such as `12:00:00Z`; a new `status-time-from-clock` grader
  requires a subagent `date -u` call. F1: Edit rows start with `"replace_all"`, so Edit-aware patterns now
  allow it. F3: the test-engineer rubric allows a broken copy outside the workspace. F4: the e2e prompt says
  the CSV export is internal, so #13's new wording keeps it size M. F5/F6: the decisions graders anchor on the
  `decisions.md` path and read Write or Edit, and accept an ADR cited by name or path. N1-N5: the new fixture
  is executable, every "Needs" line has `Bash(date *)`, `no-compound-bash` flags redirection, the
  engineer check anchors on `subagent_type`, the verify-staffs-verifier description lists the new noise
  items. Each fixed pattern checked on positive and negative rows (scratchpad `fixcheck.mjs`). T9 hit the
  old 40-turn limit once (this session still runs the pre-fix agent definitions) and was resumed.
- **2026-10-19 T8 review of the text: approve, with 5 should-fix and 4 nits, all applied by the organizer.**
  Long output: agents read the file the Bash tool saves, from the end (the tool shows only the start). #19:
  the recheck is a new task with its own status file, and "fix and close" after a second request for changes
  is allowed only for a small local fix; otherwise the user decides on a third review. The reviewer writes
  findings every two or three, not one Write and one `date -u` per finding. A "Regressions to catch" brief
  gives the exact command for the broken copy, folder included. Nits: `protocol.md` says no `cd`; the tier
  signals count consumed formats; the `formats.md` examples agree with each other and with the `&&` exception.
  T8 also found that Claude Code 2.1.299 lists `date -u` as a read-only command, so #21 most likely adds no
  prompt; `"Bash(date *)"` in eval runs is harmless either way.
- **2026-10-19 T10 recheck of the fix round: approve.** Every T8 and T9 finding resolved. Its two should-fix
  findings and two nits were size S, so the organizer fixed and closed them under the new #19 rule: the
  verifier finds the first failure in the saved output file (F-1); a regressions brief names the copy's
  folder and prefers a folder argument over `cd … &&` (F-2); the clock grader is tied to the reviewer, which
  the e2e case always staffs (N-a); the recheck sentence says "size S" (N-b). Not done: N-c (an escaped
  apostrophe can confuse `no-compound-bash`; no real trace triggers it).
- **2026-10-19 T11 first eval round ($5.42).** Organizer suite 6/8 at 1.00 ($4.50): medium-fix-end-to-end 1.00
  (the organizer ran `node --test` itself, no compound command, the reviewer read the clock),
  plans-against-project-conventions 1.00 (new, #7), starts-work-item-on-large-request 1.00 plus 2 more runs at
  1.00 ($0.75; #13 sized L 3/3, #18 table present 3/3), file-issue profile-confirm-never-creates 1.00
  ($0.17; the guard works in the real harness). Two graders failed: verify-staffs-verifier `real-retry-kept`
  (0.92) and test-engineer-keeps-failing-test `defect-goes-back` (0.83); both rerun with `--keep-temp` to
  tell a regression from a brittle grader.
- **2026-10-19 T11 diagnosis.** `test-engineer-keeps-failing-test` rerun: 1.00 ($1.03), so the earlier
  `defect-goes-back` miss was judge variance on the final reply (this case has scored 0.80 before).
  `verify-staffs-verifier` reproduced its miss ($1.43, sandbox kept): the organizer kept every noise item it
  should and removed the debug log and the log-and-rethrow, but deleted `writeRow` on purpose: "It wasn't in
  the plan, nothing called it, and its retry could write a row up to three times." That is a sound scope call;
  the fixture was wrong. The fixture now puts the retry in the brief, plan and decisions (the sink upserts by
  row number), calls it from `exportRows`, and tests it. Rejected: loosening `real-retry-kept` (it would stop
  catching a real over-strip).
- **2026-10-19 Second verify-staffs-verifier rerun ($0.79): retry kept; the crew found two of the organizer's own
  mistakes.** The opus reviewer showed that the fixture's "upserts by row number" claim was false (`write`
  received only the line) and that permanent errors were retried; the fixture now passes the row number and
  retries transient errors only. My `protocol.md` example `node --test /tmp/copy/test` was wrong (Node 22
  doesn't take a folder there), and the organizer copied that form into the verifier's command; the example
  is now `pytest /tmp/copy/tests`. `failure-reported` failed on a reply that said db-check "fails with
  ECONNREFUSED" without an exit code; the judge now accepts a plain "fails" with the error and still fails a
  "passed" claim. `real-retry-kept` accepts the transient condition next to the attempt limit.
- **2026-10-19 T11 done: every case passes; eval spend $9.96.** Final `verify-staffs-verifier` 1.00 ($1.29, all
  13 graders). Totals: organizer suite $4.50, large-request ×2 $0.75, file-issue case $0.17, diagnostic and
  confirming reruns $4.54. Issue status for the PR: #7, #12, #13, #15-#19, #21, #22 resolved with evidence;
  #14's text change is in, but its acceptance check (a 10-file review finishing unresumed) needs a session
  that loads the new reviewer definition, since this session's reviewers still ran the old 40-turn one.
- **2026-10-19 Closed.** Merged in PR #24; ten issues closed by it, #14 left open until a review in a session
  with the new reviewer definition finishes unresumed. `retro.md` written at close: 4 proposals (L1 profile
  note; L3, L4, L5 README conventions) and 4 follow-up issue drafts (the medium-fix fixture's syntax error,
  bash fixtures vs POSIX docs, whether a grader's file path globs, the verifier's folder handling) wait for the
  user's answer; the other lessons are fixed in this item (#12, #19) or tracked (#14).
- **2026-10-19 The user accepted every retro proposal and every follow-up.** P1 profile note and P2-P4 README
  conventions applied; follow-ups filed as #25 (fixture syntax error), #26 (bash fixtures vs POSIX docs),
  #27 (grader path glob), #28 (verifier subfolder commands).
