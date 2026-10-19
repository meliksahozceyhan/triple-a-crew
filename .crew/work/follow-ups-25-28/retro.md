# Retro: follow-ups-25-28

**Closed:** 2026-10-19

## What happened
- The item closed the four follow-ups filed when `fix-open-issues` closed (#25-#28). The plan held, with two
  changes: T3 changed no grader, because T1 found that a file target takes no glob, so the graders stay on the
  trace and only the README changed; and SKILL.md was touched after all (in place, still 160 lines), because
  the review found step 8 still named a separate folder for the verifier (decisions.md "T1", "T4 review")
- The organizer had judged step 8's wording consistent with the #28 fix; the T4 reviewer showed that the
  contradiction had only moved from `verifier.md` to SKILL.md (team/T4-reviewer.md should-fix)
- T4 checked each issue's acceptance criteria one by one, the practice #30 proposes, and that is how it found
  the step 8 contradiction (team/T4-reviewer.md "Progress")
- T4 hit its 60-turn limit once, mostly checking where a subagent's Bash calls start in the CLI binary, a side
  question; its findings were already on disk, so the resume cost little (decisions.md "T4 review")
- The T1 researcher, staffed after `/reload-plugins`, wrote an invented `updated` time (`20:30:00Z`, after the
  file's last change), although its agent file says to take it from `date -u` (findings.md)
- `medium-fix-end-to-end` scored 1.00 ($0.81) on the repaired fixture (decisions.md "T5")
- The user said #31 was merged before it was; the organizer checked the PR state with `gh pr view` and
  waited, so no branch was deleted early this time (session)

## Lessons
| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| L1 | A sonnet employee still wrote an invented `updated` time after the `date -u` rule shipped and the plugin was reloaded; the text rule alone doesn't hold | findings.md, team/T1-researcher.md:6 | agent-teams-mode L4, fix-open-issues | https://github.com/meliksahozceyhan/triple-a-crew/issues/32 | filed |
| L2 | The reviewer ran out of turns again, this time on a side question, not the diff size; #14's fix (findings written as it goes) held, so nothing was lost | decisions.md "T4 review" | crew-hooks L2, retro-skill L2, fix-open-issues L2 | https://github.com/meliksahozceyhan/triple-a-crew/issues/14 (fixed; held here) | kept |
| L3 | Checking each closed issue's criteria one by one found a contradiction the organizer had missed | team/T4-reviewer.md | | https://github.com/meliksahozceyhan/triple-a-crew/issues/30 (work item `issue-30-criteria-check`) | kept |
| L4 | A rule changed in one file stayed stated the old way in another (SKILL.md step 8 vs `verifier.md`) | team/T4-reviewer.md should-fix | | `.crew/profile.md` note | accepted |
| L5 | "Merged" can be said before the merge lands; check the PR state before closing or deleting a branch | session (#29, #31) | review-24-fixes L5 | `.crew/profile.md` note | accepted |

## Proposed text
- **L1** (issue draft for the plugin repository), title "Employees still write invented `updated` times
  after the `date -u` rule": "After the rule to take `updated` from `date -u` shipped (#21) and the plugin was
  reloaded, a researcher on the standard tier still wrote a round, invented time (`…T20:30:00Z`) that was later
  than the file's last change. The text rule alone doesn't hold. Suggested fix: the SubagentStop hook compares
  the status file's `updated` with the clock and blocks the stop, with the exact `date -u` command to run, when
  the time is in the future or missing. Acceptance: the hook test has a future-time case that blocks and a
  real-time case that passes."
- **L4** (`.crew/profile.md` note): "A rule here is often stated in several places: `SKILL.md`, `protocol.md`
  and an agent file (follow-ups-25-28: the verifier's folder rule). When one changes, grep the others for the
  same rule before review."
- **L5** (`.crew/profile.md` note): "Before closing a work item or deleting its branch, confirm the PR is
  merged with `gh pr view <n> --repo meliksahozceyhan/triple-a-crew --json state`; the user may say "merged"
  before GitHub has it (review-24-fixes, follow-ups-25-28)."
