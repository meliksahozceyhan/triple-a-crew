# Retro: employees-v2

**Closed:** 2026-10-19

## What happened
- The docs did not say whether a plugin agent's `skills:` preloads a plugin skill (team/T1-researcher.md); a
  $0.007 haiku probe showed the bare name works and `plugin:x` loads nothing, silently (decisions.md
  "`test-engineer` preloads with the bare name")
- T2-T5 finished without rework; T3 and T5 ran in parallel on disjoint files (board.md, decisions.md)
- The organizer ran `verify-staffs-verifier/fixture.sh` in the repository root: a local commit on the branch,
  and `.crew/profile.md` and `.crew/work/index.md` overwritten; undone the same minute, nothing pushed
  (findings.md)
- The first verifier eval scored 0.86: the verifier wrapped each command in a compound line that the allow
  rule denied; the organizer, the researcher and the test-engineer chained commands too (findings.md)
- Review: 2 must-fix, 9 should-fix, 6 nits, then a re-check with more items before "ship". M1: a pipe made a
  failing suite report exit 0. M2: the brief's done-when asked for an eval case per built role, and the plan
  covered only the verifier (team/T8-reviewer.md, decisions.md "T8 review fixes")
- The organizer suite sized the large request M once in 6 runs (findings.md, decisions.md "T9")
- Two `llm` judges with `focus: trace` missed facts at the end of a run log of about 330 KB; they now judge
  the final reply (decisions.md "T9 results")
- Eval cost for the item: about $8.22 (decisions.md "T9 results")

## Lessons
| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| L1 | When the docs leave a mechanic open, a cents-cheap live probe settles it | team/T1-researcher.md, decisions.md | crew-hooks L1 | `README.md` "Conventions for new skills" | accepted |
| L2 | Run an eval fixture only in an empty temp folder | findings.md | | https://github.com/meliksahozceyhan/triple-a-crew/issues/15 | accepted |
| L3 | Compound shell lines don't match allow rules and hide exit codes | findings.md, team/T8-reviewer.md M1 | | https://github.com/meliksahozceyhan/triple-a-crew/issues/12 | accepted |
| L4 | The sizing table doesn't name a consumed format as public API | findings.md | | https://github.com/meliksahozceyhan/triple-a-crew/issues/13 | accepted |
| L5 | A trace judge can miss facts near the end of a long run | decisions.md "T9 results" | | `README.md` "Conventions for new skills" | accepted |
| L6 | A plugin agent's `skills:` preloads only by the bare name, and nothing records that | decisions.md "`test-engineer` preloads"; docs/DESIGN.md "Verified mechanics", Agents row | | `docs/DESIGN.md` "Verified mechanics" | accepted |
| L7 | The plan missed a done-when criterion, and nothing caught it until the review | team/T8-reviewer.md M2 | https://github.com/meliksahozceyhan/triple-a-crew/issues/18 | accepted |
| L8 | The re-check after the review fixes found more items | decisions.md "T8 re-check" | crew-hooks L4 | `retro.md` only (durable fix proposed in retro-skill L5) | kept |

## Proposed text
- **L1** (`README.md`, "Conventions for new skills", a new bullet after "Never invent values"):
  "**Probe what the docs leave open.** When a skill depends on a Claude Code mechanic the docs don't settle,
  run a throwaway plugin on haiku in a scratch folder (it costs cents) and record the result with its date in
  DESIGN's Verified mechanics. `crew-hooks` (hook payloads) and `employees-v2` (`skills:` names) both did."
- **L5** (`README.md`, "Conventions for new skills", end of the "Ship evals with the skill" bullet): "A
  trace judge can miss facts near the end of a long run (about 330 KB in `employees-v2`); when the final
  reply carries the facts, judge the final reply."
- **L6** (`docs/DESIGN.md`, "Verified mechanics", Agents row): append to What holds "A plugin agent's
  `skills: [x]` preloads the plugin's own skill only by its bare name; `plugin:x` loads nothing, silently,
  and eval traces never show the injected text", and to Source "; probe 2026-10-19 (`employees-v2`)".
- **L7** (issue draft for the plugin repository), title "Organizer's plan can miss a done-when criterion
  until review": "In a size-L item the brief's done-when asked for an eval case for every new role. The
  plan had a task for only one of them, the go-ahead was given, and the reviewer caught the gap as a
  must-fix after the work was built. Step 5 (Plan) never checks that each done-when line maps to a task.
  Suggested fix: before showing the plan, list each done-when line with the task that meets it; a line
  with no task becomes a task or is recorded as deferred in `decisions.md`. Acceptance: the size-L plan
  shown to the user names a task (or a recorded deferral) for every done-when line."
