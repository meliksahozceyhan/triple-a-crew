# Plan

Recommendation: build `verifier` and a thin `test-engineer`, fold `architect` into `researcher`, drop
`scribe` (reasons in decisions.md).

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | Confirm in the docs that a plugin agent's `skills:` frontmatter preloads a plugin skill (`triple-a-crew:test-harden`) for a subagent | read only | answer with doc URL and section | researcher | mechanical | - |
| T2 | `verifier` agent: runs the profile's `verify` commands in order, all of them even after a failure; reports each command's exit code, duration and the first failing lines verbatim; never edits, never "fixes", one rerun only to label a flaky command | plugins/triple-a-crew/agents/verifier.md | file validates; brief/report sections match protocol.md | engineer | standard | - |
| T3 | `test-engineer` agent: writes tests only (never production code) in its file set, preloads `test-harden` (or reads it if T1 says no preload), project framework only | plugins/triple-a-crew/agents/test-engineer.md | file validates; no production paths in its scope rules | engineer | standard | T1 |
| T4 | Fold `architect`: a "Design questions" section in the researcher (2-3 options, trade-offs, cost of reversal, recommendation, lines ready for decisions.md); staffed at critical tier | plugins/triple-a-crew/agents/researcher.md | section present; bug-investigation section unchanged | engineer | standard | - |
| T5 | Organizer wiring: roles table and rules (verifier on step 8 for L, and for M when verify output is long; tests from a different employee than the code; design questions to a critical researcher) | plugins/triple-a-crew/skills/work/{SKILL.md,staffing.md} | steps name the new roles; no step depends on them being available | engineer | standard | T2, T3, T4 |
| T6 | Eval cases using a pre-scaffolded work item at phase `verify`, run with `/triple-a-crew:work next`: the organizer staffs `verifier` on haiku, the verifier reports the failing command's exit code and edits nothing; the same fixture puts a debug log in the changed lines, which also covers half of issue #7 | plugins/triple-a-crew/evals/verify-staffs-verifier/ (new) | case passes at --runs 1; fails if verifier edits code | engineer | standard | T5 |
| T7 | Docs: staffing roles, README employees table and evals, DESIGN Employees and migration notes | README.md, plugins/triple-a-crew/README.md, docs/DESIGN.md | grep shows no "come later" for built roles | engineer | mechanical | T5 |
| T8 | Review the full diff | read only | verdict + findings | reviewer | critical | T6, T7 |
| T9 | Run the organizer suite + new cases at --runs 1, report cost | read only | all 1.00 | organizer | mechanical | T8 |

T2 and T4 can run in parallel (disjoint files). T3 waits for T1.
