# Retro: organizer-rules

**Closed:** 2026-11-13

## What happened
- Two researchers (T1, T2) mapped where each rule is stated before any plan. A 40-second probe (P1) of a
  worktree-isolated employee overturned the execution plan: it cannot write its status file in the main
  checkout. The rule was removed, and engineers worked in the branch's own worktree by absolute path
  (decisions.md)
- T3, T4 and T5 each owned reference files and ran in parallel; the organizer then wrote `SKILL.md` alone
  (T6), which stayed at 160 lines through three rounds of changes. T7 (docs) and T8 (eval cases) ran in
  parallel after it (board.md)
- Verify passed (T10). Two first reviews asked for changes. T11, rule text: the trigger for the current flow
  was circular, and the repeat rule read three ways. T11b, eval cases: the flow case could fail a correct run
  and pass a plan with no flows (team/T11-reviewer.md, team/T11b-reviewer.md)
- Recheck T11c: every earlier must-fix was fixed; one new must-fix came from a fix, which had reversed an
  edge case of the brief without a recorded decision. The round touched about ten files, so step 8 said to
  ask the user about a third reviewer; there was no answer by the time the pull request was opened, so there
  was none (team/T11c-reviewer.md; decisions.md)
- All three reviewers had a tool-call budget and finished with a verdict: 31 of 45, 52 of 55, 39 of 51
- Evals (T12), one run each, all 1.00: the three new cases, `starts-work-item-on-large-request`,
  `plans-against-project-conventions`, `flags-unmet-ticket-criterion`, `medium-fix-end-to-end`,
  `escalates-effort-before-tier` and `writes-handoff-to-crew`; $7.96 with the reruns below (decisions.md)
- The flow case needed three runs: 0.71, 0.86, 1.00. `plan.md` had the diagrams each time, but the approval
  message first retold them in prose and then showed them without the final flow's marks. Neither review
  had caught that; two sentences in `formats.md` fixed it (decisions.md)
- One eval command failed at no cost: `--case` takes one glob, not a list of names (decisions.md)

## Lessons
| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| 1 | The recheck after review fixes found a new must-fix, caused by a fix | team/T11c-reviewer.md MF1 | L1 | `retro.md` only (the recheck rule is the mechanism, and it worked) | kept |
| 2 | A changed rule read differently in another file in both review rounds, although every brief carried its exact words | team/T11-reviewer.md MF2; team/T11c-reviewer.md S3 to S5 | L7 | `.crew/profile.md` note | proposed |
| 3 | An eval run of a new case found two gaps that two review rounds had missed | decisions.md, "T12" | | `README.md`, "Conventions for new skills" | proposed |
| 4 | A cheap live probe overturned the execution plan before anything depended on it | decisions.md, "F" | L5 | `retro.md` only (the convention exists) | kept |
| 5 | The brief's own edge-case row contradicted the issue it was built from | team/T11c-reviewer.md MF1 | | `retro.md` only | kept |
| 6 | `claude plugin eval --case` takes one glob, not a list of names | decisions.md, "T12" | | `.crew/profile.md` note | proposed |

The ledger rows for this item and its two sibling items are updated in the release pull request, once all
three are on `main`.

## Proposed text
- **2** (`.crew/profile.md` note, added to the "A rule here is often stated in several places" note): "The
  last review's brief lists each changed rule with the words it hinges on and asks for a grep of every file
  that states it (`organizer-rules`: two rounds each found a copy that differed)."
- **3** (`README.md`, "Conventions for new skills", in "Ship evals with the skill"): "Run a new case once
  before the first review, not after the last: it costs about as much as a tenth of a review round, and it
  sees what the model does, which a reviewer of the text cannot (`organizer-rules`: the flow case found that
  the approval message retold the diagrams in prose)."
- **6** (`.crew/profile.md` note, added to the eval note): "`--case` takes one glob, not a list: run several
  named cases as separate commands, or by a shared prefix or `--tag`."
