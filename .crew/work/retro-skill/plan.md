# Plan

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | `retro` skill: read the item's brief, plan, decisions, findings, board and `team/` files; compare plan with outcome (tasks done vs planned, acceptance misses, escalations, blocked questions, reviewer must-fixes, findings filed, user corrections); read earlier `.crew/work/*/retro.md` and call out repeats; route each lesson (project → proposed profile note or convention edit, asked first; crew → plugin finding offered through `file-issue`; one-off → kept in retro.md only); write `retro.md` | plugins/triple-a-crew/skills/retro/SKILL.md | under ~150 lines; portable frontmatter; never writes user-owned profile fields | engineer | standard | - |
| T2 | `retro.md` format (committed, part of the durable record) | plugins/triple-a-crew/skills/work/formats.md | format listed and marked committed | engineer | mechanical | T1 |
| T3 | Organizer close step runs `retro` for M and L items, before moving the item to Closed | plugins/triple-a-crew/skills/work/SKILL.md | step 10 names it; still works when the skill is missing | engineer | mechanical | T1 |
| T4 | Eval cases: `retro-flags-repeat` (a closed item whose verify failed on a flaky test, and an earlier retro with the same problem: retro.md calls out the repeat, proposes a profile note, does not write profile.md); `retro-on-request` with a baseline ("let's do a retro on csv-export"); `no-fire-retro-question` near miss ("what goes in a sprint retrospective?") | plugins/triple-a-crew/evals/retro-*/ | pass at --runs 1; the trigger case shows Δ > 0 | engineer | standard | T1 |
| T5 | Docs: README skills table, `.crew/` folder table (retro.md committed), DESIGN lifecycle and close step | README.md, plugins/triple-a-crew/README.md, docs/DESIGN.md | grep shows retro in each | engineer | mechanical | T3 |
| T6 | Review the full diff | read only | verdict + findings | reviewer | critical | T4, T5 |
| T7 | Run the new cases (with baseline for the trigger case) and the organizer suite at --runs 1, report cost | read only | all pass; Δ recorded | organizer | mechanical | T6 |

T1 first; T2 and T4 can run in parallel after it (disjoint files).
