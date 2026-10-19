# Retro: review-24-fixes

**Closed:** 2026-10-19

## What happened
- The item existed because a post-merge review of #24's whole diff found that #17, #18 and #22 didn't meet
  their own acceptance criteria. #24's reviews had been split by area (text vs evals), and none checked each
  closed issue's criteria end to end (brief.md, `fix-open-issues/team/T12-reviewer.md`)
- The organizer fixed it itself (size M). Its own fix round introduced two must-fixes the T2 review caught:
  compressing step 8 to stay within 160 lines dropped the "fix is size S" condition, and the first
  `regressions-shown` counted the control run as proof (team/T2-reviewer.md)
- A regex written through a Python string came out double-escaped; the sample probe caught it before commit
  (decisions.md "T2 review")
- The new step 8 rule worked as written: the one recheck approved, its size-S findings were fixed without a
  third review (decisions.md "T4 recheck")
- The evals ran with `--keep-temp`, and the kept trace showed the test-engineer's whole regression proof, more
  than the run-count grader can (decisions.md "T3 evals")
- The organizer deleted a local branch before #29 was actually merged, and restored it from GitHub (session)

## Lessons
| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| L1 | Reviews split by area left each closed issue's acceptance criteria unchecked end to end | `fix-open-issues/team/T12-reviewer.md` M1-M3 | | https://github.com/meliksahozceyhan/triple-a-crew/issues/30 | accepted |
| L2 | Trimming text to fit the line budget dropped a condition | team/T2-reviewer.md must-fix 2 | | `retro.md` only | kept |
| L3 | The recheck after the fixes found new problems again, and the new step 8 rule handled them | team/T4-reviewer.md | fix-open-issues L6 | https://github.com/meliksahozceyhan/triple-a-crew/issues/19 (fixed; worked here) | accepted |
| L4 | A kept sandbox shows behavior a grader can only approximate | decisions.md "T3 evals" | | `retro.md` only | kept |
| L5 | Check a PR is merged before deleting its branch | session | | `retro.md` only | kept |

## Proposed text
- **L1** (issue draft for the plugin repository), title "Final review doesn't check each closed issue's
  acceptance criteria": "When a work item closes several issues and its reviews are split by area, no
  reviewer checks each issue's acceptance criteria against the whole result. In one item, three closed issues
  turned out to have unmet criteria (a grader that could not fail, a 'shown' check that was never checked, a
  plan table the user never saw). Suggested fix: when a PR closes issues, the organizer's last review (or a
  short extra check) lists each issue's acceptance criteria and the evidence for each, and a criterion with no
  evidence becomes a must-fix or a recorded deferral before 'Closes #N' goes in the PR."
