# Plan

From T1: fixtures run in an empty workspace with no harness variable, so the #15 guard is an emptiness check;
no grader option scopes to the main agent, but a `regex` grader on the trace can (`"parent_tool_use_id":null`
marks main-agent rows); an `llm` judge on the trace sees only the first and last 12 messages; both cut
fixtures (344b75e) can seed the #7 cases.

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | Eval-harness facts for #15, #17, #7, #12 | read only | done: team/T1-researcher.md | researcher | standard | - |
| T2 | Organizer text: one plain command per Bash call for the organizer, and for employees in the brief rules (#12); consumed formats count as public API (#13); size-L plans map every done-when line to a task or a recorded deferral (#18); a fresh reviewer rechecks the fix diff when a review requested changes, one automatic round (#19); status-file `updated` from `date -u` in the template (#21); test-task briefs for risky work list 3-5 regressions to catch (#22) | skills/work/SKILL.md, protocol.md, staffing.md, formats.md | each issue's text present; SKILL.md at most 160 lines (details in reference files); `claude plugin validate .` passes | engineer | standard | approval |
| T3 | Agent files: one plain command per Bash call, long output read from a file (#12); the reviewer writes each finding to its status file as it goes, `maxTurns` 40 to 60 (#14); `updated` from `date -u` in every status template (#21); the test-engineer shows each listed regression failing on a copy outside the repo (#22) | plugins/triple-a-crew/agents/*.md | each rule present in the right agents; `claude plugin validate .` passes | engineer | standard | approval |
| T4 | Every fixture refuses to run unless its folder is empty, before writing anything (#15) | plugins/*/evals/*/fixture.sh (13 files) | each fixture exits 1 and writes nothing in a non-empty temp folder, and exits 0 in an empty one (run only inside `mktemp -d`) | engineer | standard | approval |
| T5 | Eval coverage: `medium-fix-end-to-end` allows Bash and checks the organizer ran `node --test` itself (#17) and that no agent chained commands (#12); `starts-work-item-on-large-request` checks done-when coverage in plan.md (#18); `test-engineer-keeps-failing-test` checks the regressions list (#22); new size-L case for the convention check and an extended noise-rule fixture (#7); placeholder-time check where cheap (#21) | plugins/triple-a-crew/evals/ (changed and new cases) | each new grader passes on the intended behavior and is shown to fail on a counter-example (a hand-written trace line or file); fixtures keep the T4 guard | test-engineer | standard | T2, T3, T4 |
| T6 | Docs: README "Conventions for new skills" (#16: anchor on `"file_path"`, main-agent `regex` graders, the 12+12 trace-judge limit, fixtures refuse non-empty folders), README/DESIGN for the rule changes, eval table rows | README.md, docs/DESIGN.md, plugins/triple-a-crew/README.md | every changed rule described once; links resolve | organizer | standard | T2-T5 |
| T7 | Verify the combined result | read only | profile verify commands: exit codes and failing output | verifier | mechanical | T2-T6 |
| T8 | Review the organizer and agent text (T2, T3, T6) | read only | verdict + findings with failure scenarios | reviewer | critical | T7 |
| T9 | Review the fixtures and eval cases (T4, T5) | read only | verdict + findings | reviewer | critical | T7 |
| T10 | Recheck the fix diff if T8 or T9 requested changes (#19, dogfooded) | read only | verdict | reviewer | critical | fixes |
| T11 | Evals at `--runs 1`: organizer suite plus new cases; `starts-work-item-on-large-request` three times (#13); `file-issue`'s `profile-confirm-never-creates` (its only fixture changes in T4) | read only | all 1.00, cost reported | organizer | mechanical | T8-T10 |

T2, T3 and T4 run in parallel (disjoint files). T5 follows them, T6 follows T5. Reviews run after verify.

## Done-when coverage
| Done-when line (brief.md) | Covered by |
|---|---|
| Every issue's acceptance criteria hold, or a deferral is recorded | T2-T6, decisions.md |
| The profile's verify passes | T7 |
| Organizer suite 1.00 and new or changed cases pass | T11 |
| SKILL.md about 150 lines | T2 acceptance check |
| One PR that closes the issues it resolves | organizer, after T11 |
