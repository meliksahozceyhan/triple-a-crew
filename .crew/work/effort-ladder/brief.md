# Effort as a knob, and an explicit escalation ladder

**Size:** M · **Tickets:** none (user request) · **Opened:** 2026-10-20

## What
The organizer passes only `model` when it spawns an employee (SKILL.md:94). `effort`, the Agent tool's
`low | medium | high | xhigh | max`, is never set, although `docs/DESIGN.md:143` says the organizer overrides
it per task and `DESIGN.md:180` calls it "the second knob". The escalation rule (SKILL.md:111,
staffing.md:41) says: a miss is sent back once; a second miss re-staffs one tier up. It doesn't say what
counts as a miss beyond the acceptance check, what happens after the top tier misses, how a re-staffed
attempt is named, or how attempts are recorded, so after `/clear` the organizer can't tell which rung it's on.

This item:
1. an effort column in the tier table, with a default and a ceiling per tier;
2. `effort` passed at spawn next to `model`, and a default `effort:` in each agent file;
3. the ladder written out: miss 1, send the same employee back once (it keeps its context); miss 2,
   re-staff at the same tier with effort one step up; miss 3, re-staff one tier up at that tier's default
   effort; miss 4, or no rung left, ask the user. Every re-staffed attempt gets its own status file
   (`T1b-engineer.md`; the hook matcher already accepts the letter) and a brief carrying every earlier
   failure verbatim;
4. the board records each attempt's model, effort and outcome;
5. one eval case that fails on the current text and passes on the new one.

## Why
The user wants a loop: difficulty → model and effort, check, retry upward, bounded. Most of it exists in
steps 2, 5-8. The effort knob is designed but never turned, and the ladder's triggers, top and bookkeeping
are unwritten. Writing them down makes the loop cheaper (effort before model), resumable (board) and finite
(ask the user).

## Done when
- [ ] (derived) `staffing.md`'s tier table has an effort column with a default and ceiling per tier, and
      step 6 passes `effort` with `model`; the new case's trace shows an engineer spawned with
      `"effort":"high"`.
- [ ] (derived) The ladder is explicit in `staffing.md`, pointed to from step 7: send back once → effort up
      one step at the same tier → one tier up → ask the user. What counts as a miss is named: a failed
      acceptance check, a verify failure or reviewer must-fix attributed to the task; not a `flaky` result,
      not a `blocked` question, not a test-engineer's failing test that exposes a code bug.
- [ ] (derived) A re-staffed attempt has its own status file, `<task><letter>-<role>.md`, and its brief
      carries every earlier failure verbatim (the check that failed and the command output).
- [ ] (derived) `board.md` (formats.md) records each attempt with model, effort and outcome, so `next`
      after `/clear` resumes at the right rung.
- [ ] (derived) Each agent file sets a default `effort:`; the spawn value wins (DESIGN "Precedence").
- [ ] (derived) `escalates-effort-before-tier` fails on the current text and scores 1.00 on the new one;
      `medium-fix-end-to-end` and `verify-staffs-verifier` still score 1.00.
- [ ] (derived) Profile verify passes; `SKILL.md` stays at most 160 lines with no condition dropped;
      `teams.md`, README and `DESIGN.md:143/170-182` agree with the shipped rule; an opus reviewer approves
      after checking each line above with evidence.

## Constraints
- README "Conventions for new skills": earn the place (the case must fail on the current text; baseline
  before the text changes), one case per key rule, a fixture consistent with its own work item, graders
  probed on real trace rows and on the near miss, run every command example. The two lessons from
  `issue-30-criteria-check`: the fixture must hold back the rule's own output (no "effort" or "ladder"
  wording in it), and whether the case can fail on the current text is settled first (yes, by
  construction: the current text prescribes a tier jump at miss 2, the new text an effort step).
- `SKILL.md` budget 160 lines, currently exactly 160: the ladder's detail goes to `staffing.md`; trimming
  must not drop a condition (word-diff before applying).
- Evals: `--runs 1 --ablation none`, `"Bash(date *)"` in `--allow-tools`, `--keep-temp` for the new case;
  report the cost; fixtures only in `mktemp -d`.
- Subagent mode and team mode (`teams.md`) both keep working. Ask before pushing; the user merges.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| Tier already critical when effort has been raised once | yes | no rung above critical → ask the user |
| Effort already at the tier's ceiling (`xhigh`) at miss 2 | yes | skip to tier up; ceilings are in the table; `max` is never climbed to |
| `models:` override in the profile (e.g. `critical: fable`) | yes | tier up uses the profile's model; effort rule unchanged |
| `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` forces one model | yes | existing rule kept: record the actual model; a tier up is recorded as asked and as run |
| haiku given an effort value | yes | harmless if ignored; the case's verifier row shows it's accepted |
| Teammates (`teams.md`) | yes | effort comes from the agent file's default (DESIGN:252); the spawn param is unverified for teammates, and `teams.md` says so |
| Test-engineer's failing test that exposes a code bug | yes | not a miss (existing rule, kept) |
| Verifier reports `flaky` | yes | not a miss |
| Employee `blocked` with a question | yes | not a miss: answer and resume |
| Resume after `/clear` in the middle of the ladder | yes | one board row per attempt |
| The step 8 review recheck loop (fresh reviewer, then a third-reviewer question) | yes | unchanged and separate; the text says so |
| A size-S fix the organizer makes itself that fails | no | not a staffed task; unchanged |
| The organizer's own model or effort | no | the skill can't change its own session; findings.md |
| More than 26 attempts on one task | no | the ladder has at most 4 |
