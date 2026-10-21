# Plan

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | New eval case `escalates-effort-before-tier`. Fixture: `shop-api` with a size-M item `csv-quoting` at phase implement. T1 (engineer, sonnet) quoted commas and quotes, but the test `quotes a field with a line break` fails; it was sent back once with that output and still fails. `decisions.md` and `board.md` record both misses with the failing output, and nothing else about what comes next. Prompt: `/triple-a-crew:work next`. Graders: `effort-raised-same-tier` (trace regex: a main-agent engineer row with `"model":"sonnet"` and `"effort":"high"`); `no-tier-jump` (not_contains: an engineer row with `"model":"opus"`); `failures-in-brief` (the engineer row names the failing test); `attempt-status-file` (the engineer row names `T1b-engineer.md`); `board-records-attempt` (a Write or Edit to `board.md` mentions `T1b` or `effort`); `line-break-fixed` (judge on the final reply: the line-break test passes) | `plugins/triple-a-crew/evals/escalates-effort-before-tier/` | the fixture exits 0 in `mktemp -d` and `node --test` there fails exactly the line-break test; the fixture contains no "effort" or "ladder" wording; each regex is probed on real Agent rows from the kept traces (`/private/tmp/e-UrZYkL`, `e-aReXcZ`) and on two near misses (an opus engineer row; a sonnet row without effort) | organizer | standard | - |
| T2 | Baseline on the current text, before T3 | read only | the case fails (expected: an opus engineer with no `effort`); `decisions.md` records which graders failed and why | organizer | mechanical | T1 |
| T3 | The rule. `staffing.md`: effort column (default and ceiling per tier) and "Escalate on failure" rewritten as the ladder with what counts as a miss. `SKILL.md` step 6: `effort: <level>`; step 7: the ladder in one line pointing to staffing.md, and the attempt file naming. `formats.md`: board gets an Effort column and one row per attempt, with an example. `protocol.md`: a re-staff brief carries every earlier failure verbatim. `agents/*.md`: default `effort:` per role. `teams.md`: one sentence on effort for teammates. README: how-it-works step 5, the eval row and counts (10 organizer cases, 16 in all). `DESIGN.md:143` and `:170-182`: aligned with the shipped ladder | `skills/work/staffing.md`, `SKILL.md`, `formats.md`, `protocol.md`, `teams.md`; `agents/*.md`; `README.md`; `docs/DESIGN.md` | `SKILL.md` at most 160 lines; a word-diff shows no condition dropped; `grep -rn "tier up\|escalat\|effort"` across `skills/`, `agents/`, README and DESIGN finds no sentence that contradicts the ladder | organizer | critical | T2 |
| T4 | Run the profile's three verify commands | read only | exit codes and failing output as-is | verifier | mechanical | T3 |
| T5 | Review the whole diff against every done-when line of `brief.md`, with evidence for each (criteria table) | read only | verdict + criteria table + findings with scenarios | reviewer | critical | T4 |
| T6 | Evals at `--runs 1`: `escalates-effort-before-tier` (`--keep-temp`), `medium-fix-end-to-end`, `verify-staffs-verifier` | read only | all 1.00; cost reported; the new case's trace shows `"effort":"high"` on the engineer row | organizer | mechanical | T8 |
| T7 | Rerun the three verify commands after the T5 fixes (added per step 8) | read only | exit codes as-is | verifier | mechanical | T5 fixes |
| T8 | Recheck the T5 fix diff with the earlier findings (added per step 8) | read only | verdict + findings | reviewer | critical | T7 |

## Done-when coverage
| Done when | Met by |
|---|---|
| Effort column, defaults and ceilings; step 6 passes `effort`; trace shows `"effort":"high"` | T3, shown by T6 |
| Ladder explicit, with what counts as a miss | T3, checked by T5 |
| Re-staffed attempt: own status file, brief with every earlier failure | T3 (`protocol.md`, step 7), checked by T1's graders and T5 |
| Board records each attempt | T3 (`formats.md`), checked by T1's grader |
| Agent files set `effort:`; spawn wins | T3, checked by T5 |
| New case fails before and scores 1.00 after; two existing cases still 1.00 | T2 (fails before), T6 (after) |
| Verify passes; `SKILL.md` ≤160, no condition dropped; teams/README/DESIGN agree; reviewer approves | T4, T3, T5 |

## Not covered by an eval
The tier-up rung (miss 3) and "ask the user" (miss 4) have no case: a fixture can't make an opus engineer
fail deterministically. T5 checks that text. Recorded here so the README's eval notes say so.

## Cost
T2 about $1. T6: new case about $1, `medium-fix-end-to-end` about $0.80, `verify-staffs-verifier` about
$0.90. About $3.70 in all. Each case runs once; a rerun is asked first.
