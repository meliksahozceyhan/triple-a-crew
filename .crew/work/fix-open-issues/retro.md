# Retro: fix-open-issues

**Closed:** 2026-10-19

## What happened
- Eleven GitHub issues ran as one size-L item: a researcher first (T1, eval-harness facts), three parallel
  engineers on disjoint files (T2 organizer text, T3 agent files, T4 fixture guards), two parallel
  test-engineers (T5a, T5b; the plan's single T5 was split), the organizer's docs (T6), a verifier and two
  reviewers in parallel (T7-T9), a recheck (T10) and evals (T11) (board.md, decisions.md)
- T1's research settled four harness questions before any writer started, and its 12+12 trace-judge finding
  became a README convention (team/T1-researcher.md)
- T8 approved with 5 should-fix; T9 requested changes, one must-fix: a timestamp grader passed invented times
  (team/T8-reviewer.md, team/T9-reviewer.md)
- T8 and T9 ran out of the old 40-turn limit and were resumed; T1-T5 wrote invented `updated` times. This
  session ran the agent definitions it loaded at start, so the #14 and #21 fixes didn't apply to its own
  employees (findings.md, team/ status files)
- T10 approved the fix round and still found two should-fix items the fixes had introduced (team/T10-reviewer.md)
- T11: two first-run misses. One was judge variance. The other was a fixture flaw: `verify-staffs-verifier`
  planted out-of-plan, unused retry code, which the organizer rightly deleted. In the next rerun the reviewer
  showed the fixture's "upserts by row number" claim was false, and the organizer copied a wrong example
  from `protocol.md` (`node --test <dir>`) into a verifier brief. All fixed; $9.96 in evals (decisions.md)
- The organizer's own `cd` moved the session folder twice during this item (session transcript)
- A grader pattern built on hand-made trace rows missed the real shape: Edit rows start with `"replace_all"`
  (team/T9-reviewer.md F1)

## Lessons
| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| L1 | A session keeps the agent and skill definitions it loaded, so employees miss fixes made during the item until `/reload-plugins` | findings.md; team/T8-reviewer.md, team/T9-reviewer.md | | `.crew/profile.md` notes | proposed |
| L2 | The reviewer's turn limit ran out on large reviews again | team/T8-reviewer.md, team/T9-reviewer.md | crew-hooks L2, retro-skill L2 | https://github.com/meliksahozceyhan/triple-a-crew/issues/14 | accepted |
| L3 | A fixture's planted change contradicted its own work item (out of plan, unused, a false claim), so the organizer rightly changed it and a grader failed for the wrong reason | decisions.md "T11 diagnosis", "Second verify-staffs-verifier rerun" | | `README.md` "Conventions for new skills" | proposed |
| L4 | A wrong command example in skill text got copied literally into a brief | decisions.md "Second verify-staffs-verifier rerun" | | `README.md` "Conventions for new skills" | proposed |
| L5 | Regex graders tested only on hand-made rows missed the real trace row shape | team/T9-reviewer.md F1 | retro-skill L1 | `README.md` "Conventions for new skills" | proposed |
| L6 | The recheck after the fixes found new problems again | team/T10-reviewer.md | crew-hooks L4, employees-v2 L8, retro-skill L5, agent-teams-mode L2 | https://github.com/meliksahozceyhan/triple-a-crew/issues/19 (fixed in this item) | accepted |
| L7 | The organizer's own `cd` moved the session folder | session transcript | agent-teams-mode L3, L7 | https://github.com/meliksahozceyhan/triple-a-crew/issues/12 (fixed in this item) | accepted |
| L8 | Read-only roles (verifier, reviewers) ran in parallel with no conflicts | board.md | | `retro.md` only | kept |

## Proposed text
- **L1** (`.crew/profile.md`, notes, one new bullet): "A running session keeps the agent and skill definitions
  it loaded at start. After changing a file in `plugins/*/agents/` or `plugins/*/skills/`, run
  `/reload-plugins` before staffing employees, or they follow the old text (fix-open-issues: reviewers hit the
  old 40-turn limit, employees wrote invented timestamps)."
- **L3** (`README.md`, "Conventions for new skills", end of the "Ship evals with the skill" bullet): "A
  fixture's planted change must agree with its own work item: in the plan, used, and correct. Otherwise the
  organizer rightly changes it, and the case fails for the wrong reason (`verify-staffs-verifier` once planted
  an unused retry the organizer deleted)."
- **L4** (`README.md`, "Conventions for new skills", a new bullet after "Never invent values"): "**Run every
  command example.** Models copy examples literally: a wrong `node --test <dir>` in `protocol.md` turned up in
  a verifier's brief."
- **L5** (`README.md`, "Conventions for new skills", end of the "Graders match what you mean" bullet): "Test a
  regex grader on rows from a real trace, not only on rows you built: Edit inputs start with
  `"replace_all"`, not `"file_path"`."
