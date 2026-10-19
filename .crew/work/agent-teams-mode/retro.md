# Retro: agent-teams-mode

**Closed:** 2026-10-19

## What happened
- The DESIGN table was rewritten from the docs (T2), but the docs left the deciding facts open; the T3 live
  test found them: a teammate's `agent_type` is its name (so the crew hooks skipped teammates), `maxTurns`
  doesn't apply, and teammates share one working tree live (team/T3-organizer.md)
- The plan changed after T3 (user-approved): a hook matcher for teammate names (T4b) and five more rules in
  `teams.md` (decisions.md "Proposed plan change")
- Review took three rounds: T7 requested changes (1 must-fix); the T7b recheck found the must-fix only
  partly fixed, three ways; the organizer rewrote the shared-tree rules around one principle; T7c said ship
  (team/T7-reviewer.md, team/T7b-reviewer.md, team/T7c-reviewer.md)
- T8 live phase A: a haiku teammate took the stop gate's "finish as failed" way out instead of doing its task;
  the gate wording was fixed (team/T8-organizer.md)
- T8 live phase B: a real size-L item ran with 13 named teammates over three rounds and followed every
  `teams.md` rule; it exposed a test-engineer mutating source in place, the organizer's `cd` leaking into
  teammates, placeholder timestamps and briefs without regressions to catch (team/T8-organizer.md)
- Evals: organizer suite 7/7 ($3.29), test-engineer case 1.00 ($0.96) (decisions.md)

## Lessons
| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| L1 | When the docs leave a mechanic open, a cheap live probe settles it | team/T3-organizer.md | crew-hooks L1, employees-v2 L1 | `README.md` "Conventions for new skills" (already there: "Probe what the docs leave open") | accepted |
| L2 | The review after the fixes found the fix partial; a second recheck was needed | team/T7b-reviewer.md | crew-hooks L4, employees-v2 L8, retro-skill L5 | https://github.com/meliksahozceyhan/triple-a-crew/issues/19 | accepted |
| L3 | A test-engineer mutated the code under test in place; the organizer's `cd` became teammates' starting folder | team/T8-organizer.md finding 11 | | fixed in this item (`teams.md`, `agents/test-engineer.md`) | accepted |
| L4 | Status files carried placeholder `updated` times | team/T8-organizer.md finding 11 | | https://github.com/meliksahozceyhan/triple-a-crew/issues/21 | accepted |
| L5 | Test-engineer briefs named no regressions to catch, which cost two review rounds | team/T8-organizer.md finding 11 | | https://github.com/meliksahozceyhan/triple-a-crew/issues/22 | accepted |
| L6 | The stop gate's escape hatch was taken as the easy way out | team/T8-organizer.md finding 5 | | fixed in this item (`scripts/subagent-stop.sh`) | accepted |
| L7 | The organizer and employees chained shell commands again | team/T3-organizer.md finding 10, team/T8-organizer.md finding 9 | employees-v2 L3 | https://github.com/meliksahozceyhan/triple-a-crew/issues/12 | accepted |
| L8 | Whether `printenv` prompts in default permission mode is still untested (the user's sessions run in auto mode) | team/T8-organizer.md | | `retro.md` only | kept |

## Proposed text
None: every lesson is already filed, fixed in this item, or kept here.
