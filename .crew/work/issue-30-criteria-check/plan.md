# Plan

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | New eval case `flags-unmet-ticket-criterion`. Fixture: a small Node CLI with a size-L work item at phase review. It closes #41 (`--since` filters orders) and #42 (an invalid `--since` exits 2 and the README documents that error), with each ticket's criteria written in its brief. Both per-task reviews approved. The README documents `--since` but not the error, so one #42 criterion has no evidence. Prompt: "Both reviews approved. Get it ready for the PR: it closes #41 and #42." Graders: `unmet-criterion-flagged` (judge on the final reply: #42's README criterion is named as unmet and #42 is not handed over as closed); `met-ticket-closes` (judge: #41 still closes, so a blanket "Refs" fails); `whole-diff-review` (regex on the trace: a reviewer is staffed and its brief names #42's README criterion) | `plugins/triple-a-crew/evals/flags-unmet-ticket-criterion/` | the fixture exits 0 in `mktemp -d`; `node --test` passes there; the README lacks the error; the regex passes and fails on sample rows taken from a real trace | organizer | standard | approval |
| T2 | Baseline: run T1's case on the current text, before T3 | read only | the case fails, and `decisions.md` records which grader failed and why. If it passes, harden the fixture once; if it still passes, record that the case only guards | organizer | mechanical | T1 |
| T3 | The rule. `SKILL.md` step 3: the brief lists each ticket's acceptance criteria as written (derived criteria marked derived). Step 8: the last review covers the whole diff against every done-when line (for size L, one more review after the per-task ones); a line with no evidence is a must-fix or a deferral the user accepts, and a ticket with an open criterion goes into the PR as `Refs`, not `Closes`. `protocol.md`: the reviewer brief's criteria list and the evidence each line needs (met, pending with the task that will show it, as given, none). `agents/reviewer.md`: reports each listed criterion with its evidence. README: the eval table row for the new case | `skills/work/SKILL.md`, `skills/work/protocol.md`, `agents/reviewer.md`, `README.md` | `SKILL.md` at most 160 lines; every condition of the old step 3 and step 8 text still present (line-by-line diff read); `teams.md` doesn't contradict it | organizer | critical | T2 |
| T4 | Run the profile's three verify commands | read only | exit codes and failing output, reported as-is | verifier | mechanical | T3 |
| T5 | Review the whole diff against every done-when line of `brief.md` and #30's two criteria, with evidence for each (the new rule, applied to itself) | read only | verdict + a criteria table + findings | reviewer | critical | T4 |
| T6 | Evals at `--runs 1`: `flags-unmet-ticket-criterion` (`--keep-temp`), `medium-fix-end-to-end`, `starts-work-item-on-large-request` | read only | all 1.00, cost reported | organizer | mechanical | T5 |

## Done-when coverage
| Done when | Met by |
|---|---|
| #30.1: step 8 or 10 says how closed issues' criteria are checked before the PR | T3, checked by T5 |
| #30.2: a PR closing an issue with an unevidenced criterion is flagged before it opens | T1, T2 (fails before), T6 (passes after) |
| Step 3 has the brief list each ticket's criteria as written | T3 |
| Verify passes, `SKILL.md` at most 160 lines with no condition dropped, a reviewer approves, `medium-fix-end-to-end` 1.00 | T3, T4, T5, T6 |

Estimated eval cost: T2 about $1.50, T6 about $3.50 (new case $1.50, `medium-fix-end-to-end` $1.25,
`starts-work-item-on-large-request` $0.40), so about $5 in all. Each case runs once; a rerun is asked first.
