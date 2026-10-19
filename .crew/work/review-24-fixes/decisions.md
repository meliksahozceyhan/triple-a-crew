# Decisions

- **2026-10-19 Size M, the organizer fixes it itself** (each fix is a line of text or one grader), a fresh opus
  reviewer checks it, and the three affected eval cases run. Scope and deferrals chosen by the user.
- **2026-10-19 Fixes (T1, organizer).** M1: `no-verifier-staffed` (Agent with a verifier `subagent_type`, max 0)
  in `medium-fix-end-to-end`. M2: `regressions-shown` in `test-engineer-keeps-failing-test`, a trace regex
  that a test-engineer ran `node --test` on a copy under `$TMPDIR` or another absolute path outside the
  workspace; its `max_turns` goes from 30 to 40 for the control run and the broken copies. M3: SKILL.md step
  5 shows the coverage and every deferral at the go-ahead; `go-ahead-shows-coverage` judges the reply. S1:
  the test-engineer copies code and tests, runs the brief's command on the unbroken copy first, then breaks
  one regression at a time from the unbroken copy. S2 and N7: one copy folder per task under `$TMPDIR`, and
  a test file path for Node (checked: `node --test <dir>` fails on Node 22 even on an unbroken copy; a file
  path passes on it and fails on a broken one). S4 and N1: after a second request for changes, a size-S fix
  is made and verify rerun; otherwise the user decides on a third reviewer. N2: any command the profile or a
  brief lists runs as listed. N3: the board example uses the full UTC time. N5: an uncaught regression is a
  gap in the test-engineer's own tests. N6: the verify fixture's header matches the case. SKILL.md stays at
  160 lines.
- **2026-10-19 Deferred: S3 and S6 (user's choice).** S3: `test-engineer-edits-tests-only` is an `llm` judge on
  the trace and can miss a mid-run edit to `src/`; a regex on Edit and Write rows by the test-engineer would
  catch it, but its paths depend on the workspace layout, so it waits for #27 (whether a file target globs).
  S6: #21's "every `updated` lies between the run's start and end" needs a time comparison that a regex
  grader can't do; the clock and placeholder graders stay as the approximation. Rejected: graders that guess
  at either.
- **2026-10-19 Not in scope (not chosen):** N4 (heading-only checks) and S5 (the organizer's `cd` exception in
  team mode); both stay in T12's status file.
- **2026-10-19 T2 review: changes requested (2 must-fix), all applied.** `regressions-shown` now needs the
  control plus three runs on a copy (four matches), accepts reporter flags and quoted or braced `$TMPDIR`, and
  rejects the workspace root; on 17 real traces it matches exactly the three where a test-engineer worked on
  copies. SKILL.md step 8 keeps the size-S condition, at the same line count. The test-engineer fixes a code
  defect in the copy only when the control fails because the code is wrong. The coverage judge names the
  five outcomes the request asks for. The copy folder is `<tmp>/<work-item id>-<task>-copy` with `<tmp>`
  from `os.tmpdir()` (works where `$TMPDIR` is unset, and two items can't share a folder). Correction: the
  test-engineer case's `max_turns` counts the organizer's turns, not the test-engineer's; 40 is harmless.
