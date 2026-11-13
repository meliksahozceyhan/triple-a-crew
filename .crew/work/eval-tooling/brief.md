# Eval tooling: grader tests without a model, and a cost map

**Size:** M · **Tickets:** two issues to be filed (D: grader tests, E: cost map) · **Opened:** 2026-11-13

## What
1. A command that checks eval graders against saved rows, with no model call (issue D).
2. A table that says which eval cases to run when a given file changes, with each case's last known cost
   (issue E).

## Why
Evals are real model calls ($4 to $10 per work item so far), so seven recorded decisions skipped a rerun for
cost. Graders were wrong about 15 times in 7 items. Three times a grader passed on a near miss, and each was
found only by a reviewer or by a paid run.

## Done when
- [ ] D.1 One command, with no model call, runs every `regex` and `tool_used` grader that has saved rows
      against a passing row and a near miss: the passing row with the wanted text removed.
- [ ] D.2 The command fails when a grader matches its near miss or misses its passing row. Shown once with a
      planted wrong grader.
- [ ] D.3 The command is in the profile's `verify` list and in README "Develop".
- [ ] D.4 README "Conventions for new skills" says a new regex grader ships with its two rows.
- [ ] E.1 A table maps each plugin area (skill, agent, hook, reference file) to the cases worth rerunning,
      with the last known cost per case and where that figure comes from.
- [ ] E.2 The table is where the organizer looks: README "Evals", pointed to from the profile's eval note.
- [ ] F.1 (derived) The profile's verify commands pass, the new one included.

The D and E lines are this brief's own until the issues are filed; then the issues' criteria replace them as
written.

## Constraints
- Neither part needs an eval run. If one is run: one run per case, cost reported (`.crew/profile.md`).
- Match the repository's test style: `test-hooks.sh` is POSIX sh, and `node` is available to verify.
- "Test a regex grader on rows from a real trace, not only on rows you built" (README "Graders match what you
  mean").
- No version bump in this item. The main checkout stays on `main`; every edit happens in a worktree.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| A grader whose regex engine differs from the test's engine | yes | plan, from T1: say what cannot be reproduced |
| A grader with no saved rows yet | yes | reported as "no rows", never as a pass |
| `llm` graders | no | they need a model; they appear in the map only |
| A near miss built by adding text to another row, not by removing it from the real row | yes | D.1, D.4 |
| Saved rows that hold local paths or names | yes | rows are trimmed to what the grader reads |
| A case whose cost was never recorded | yes | E.1 shows "unknown" |
| Cost figures going stale | no | findings.md: the table carries each figure's date |
