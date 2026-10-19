# Retro: retro-skill

**Closed:** 2026-10-19

## What happened
- T1-T4 built a standalone `retro` skill, its `retro.md` format, the organizer's close-step call and two eval
  cases; T1 and T4 each needed organizer fixes (board.md)
- The plan's third case (`retro-flags-repeat`) was folded into `retro-on-request` to save cost
  (decisions.md "Two eval cases instead of three")
- Review T6: 2 must-fix. F1: crew feedback would go to the project's tracker. F2: the "untouched" graders
  matched file names in the content of other writes (team/T6-reviewer.md)
- T7: the skill's only gain (+0.25) came from the F2 grader bug; with path-anchored graders both arms scored
  1.00, and plain Claude read the git-ignored status files on its own (decisions.md "T7: no gain")
- The user cut the skill; the organizer's step 10 now writes `retro.md` (decisions.md "Cut the standalone
  skill")
- Review T6b of the cut-and-fold: changes requested. M1: step 9 filed crew feedback into the project's
  tracker before step 10 could route it (team/T6b-reviewer.md)
- Recheck T11: ship, with one new should-fix. An accepted crew draft filed through `file-issue` would still
  reach the project's tracker. The reviewer hit its 40-turn limit again and was resumed
  (team/T11-reviewer.md, findings.md)
- Evals: $1.43 + $0.41 for the skill, $1.02 and $1.09 for the close step (decisions.md)

## Lessons
| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| L1 | Check a grader against the baseline trace before reading a Δ as the skill's gain | team/T6-reviewer.md F2, decisions.md "T7" | | https://github.com/meliksahozceyhan/triple-a-crew/issues/16 | accepted |
| L2 | The reviewer's 40-turn limit runs out on a 12-file recheck | findings.md, team/T11-reviewer.md | crew-hooks L2 | https://github.com/meliksahozceyhan/triple-a-crew/issues/14 | accepted |
| L3 | A full skill (four tasks, two reviews) was built before a baseline run showed plain Claude already does it | decisions.md "T7: no gain" | | `README.md` "Conventions for new skills" | accepted |
| L4 | `medium-fix-end-to-end` can't see whether the organizer runs verify itself | findings.md | | https://github.com/meliksahozceyhan/triple-a-crew/issues/17 | accepted |
| L5 | Every item needed a second review round, and each found something new, sometimes caused by the first round's fixes | team/T6b-reviewer.md, team/T11-reviewer.md S-new1 | crew-hooks L4, employees-v2 L8 | https://github.com/meliksahozceyhan/triple-a-crew/issues/19 | accepted |
| L6 | A routing rule fixed in one step can leak through another step (step 9 filing, then the apply step) | team/T6b-reviewer.md M1, team/T11-reviewer.md S-new1 | | `retro.md` only | kept |

## Proposed text
- **L3** (`README.md`, "Conventions for new skills", end of the "Earn the place" bullet): "Run the baseline
  arm on the case's fixture before building the skill: plain Claude's trace shows what is left to add.
  `retro` was built in full (four tasks, a review) before its baseline matched it."
- **L5** (issue draft for the plugin repository), title "Organizer closes after one review round, but the
  second round keeps finding new defects": "In three work items in a row, the review after the must-fix
  fixes found new problems: a new must-fix (a hook script exit code under dash), a nit caused by a
  first-round fix, and a should-fix showing that a routing rule fixed in one step still leaked through
  another. Step 8 says to resolve every must-fix before closing, not to review the fixes. Suggested fix: when
  a review requests changes, staff a fresh reviewer on the fix diff, briefed with the earlier findings, before
  closing. Acceptance: step 8 says so, and an M or L item whose first review requested changes shows a
  second review in its board."
