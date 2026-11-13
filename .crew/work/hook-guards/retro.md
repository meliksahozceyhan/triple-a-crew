# Retro: hook-guards

**Closed:** 2026-11-13

## What happened
- Research (T1) and a live probe (T2) ran in parallel before any plan. The probe took six haiku runs and
  changed the design twice: a hook can tell an employee's call from the main session's, so the guard acts on
  employees only; and a hook on the `Agent` call can speak to the organizer, so the stale-definition note
  goes to the organizer, not the employee (team/T2-engineer.md)
- T3, T4 and T5 ran in parallel on disjoint files in the branch's worktree, by absolute path. A probe in
  `organizer-rules` had shown that an employee in a worktree of its own cannot write its status file
  (decisions.md)
- The organizer registered both hooks and wired the two new test files into `test-hooks.sh` (T6), so the
  three engineers never touched a shared file (board.md)
- Verify 3/3 (T8). Review T9: changes requested, one must-fix, five should-fix, seven nits. The must-fix: the
  guard remembered one refused command per agent, so two refusals in one turn could never both be resent
  (team/T9-reviewer.md)
- Recheck T9b: changes requested again, one must-fix. The rewritten memory read, rewrote and renamed one
  file with no lock, so overlapping hook runs could lose a refusal. The third design, one empty marker file
  per refusal, has nothing to rewrite (team/T9b-reviewer.md)
- Both reviewers had a tool-call budget in their brief and finished with a verdict: 32 calls of 45, and 34 of
  40 (team/T9-reviewer.md, team/T9b-reviewer.md)
- Evals (T10): `session-start-mentions-open-item` 1.00 for $0.10 and `medium-fix-end-to-end` 1.00 for $0.88,
  with all hooks loaded; the guard refused nothing in that run (decisions.md)
- No finished employee of this session left a `triple-a-crew-done-*` marker, so the stop hook's report check
  seems not to run when an employee finishes through the desktop app's hand-back call (findings.md)

## Lessons
| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| 1 | The recheck after review fixes found a new must-fix, caused by the fix | team/T9b-reviewer.md R1 | L1 | `retro.md` only (the recheck rule is the mechanism, and it worked) | kept |
| 2 | Hook state that is read, changed and written back races; one file per fact does not | team/T9b-reviewer.md R1 | | `docs/DESIGN.md`, "Enforcement through hooks" | accepted |
| 3 | A cheap live probe settled six facts the docs leave open and changed the design twice | team/T2-engineer.md | L5 | `retro.md` only (the convention exists) | kept |
| 4 | Three statements in the docs did not match the scripts they describe | team/T9-reviewer.md S5 | L7 | `retro.md` only (the profile note exists; the reviewer caught it) | kept |
| 5 | The stop hook's report check may be skipped in the desktop app | findings.md | | <repository from plugin.json> | accepted (#55) |
| 6 | `claude plugin validate` may not read `hooks.json`, so it proves little for hooks | findings.md | | <repository from plugin.json> | accepted (#56) |
| 7 | Hook state falls back to a shared temp folder, and the 7-day prune can delete a live session's stamp | findings.md | | <repository from plugin.json> | accepted (#57) |

All four proposals were accepted on 2026-11-13. The three issues were filed with a fuller text than the
drafts below (context, evidence, acceptance criteria), which the user saw before filing.

## Proposed text
- **2** (`docs/DESIGN.md`, "Enforcement through hooks"): "Hook state is one small file per fact, created to
  remember and removed to forget. A hook never reads a state file, changes it and writes it back: two hook
  runs can overlap (`hook-guards`: the guard's first two designs lost refusals that way)."
- **5** (issue draft): "The stop hook's report check may not run when an employee finishes through a hand-back
  call". In the desktop app, five employees finished with complete reports and no done marker was written;
  `subagent-stop.sh` allows the stop when the input has no `last_assistant_message`. Suggested fix: probe the
  SubagentStop input in the desktop app, and read the report from the employee's transcript when the field
  is missing.
- **6** (issue draft): "`claude plugin validate` may not check `hooks.json`". It prints only the marketplace
  manifest line. Suggested fix: add a model-free check of `hooks.json` to `test-hooks.sh` (valid JSON, every
  script it names exists).
- **7** (issue draft): "Hook state files: shared temp fallback and a prune that can delete a live stamp". When
  `CLAUDE_PLUGIN_DATA` is unset the scripts write to `${TMPDIR:-/tmp}`; and the 7-day prune matches every
  `triple-a-crew-*` file, including the definition stamp of a session open longer than that. Suggested fix:
  skip state when there is no private folder, and prune stamps by session, not by age.
