# Plan

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | #27: does a grader's `{ source: file, path }` target accept a glob, and which file does it read when several match? Evidence from the eval docs and the installed CLI's code | read only | answer with evidence, plus a proposal for the graders | researcher | standard | - |
| T2 | #25: write `lines.join("\n")` in the fixture; #26: README says fixtures need bash (the harness runs them with `bash`), the hook scripts stay POSIX `sh`; #28: protocol.md and the verifier agent say a command for another folder is written in the brief as `cd "<dir>" && <cmd>` (or with the tool's own folder flag) and run as written | medium-fix-end-to-end/fixture.sh, README.md, skills/work/protocol.md, agents/verifier.md | fixture exits 0 in `mktemp -d` and `node --check src/routes/orders.js` passes there; verify passes | organizer | standard | approval |
| T3 | #27 follow-through: per T1, move the `decisions-cite-*` and `done-when-coverage` graders to file targets if globs work, or record why not; README "Conventions for new skills" states the answer | plugins/triple-a-crew/evals/{plans-against-project-conventions,starts-work-item-on-large-request}/graders/, README.md | each grader passes and fails on sample files as intended | organizer | standard | T1, T2 |
| T4 | Review the full diff | read only | verdict + findings | reviewer | critical | T2, T3 |
| T5 | Evals at `--runs 1`: `medium-fix-end-to-end`, plus every case whose graders T3 changed | read only | all 1.00, cost reported | organizer | mechanical | T4 |

## Done-when coverage
| Done when | Met by |
|---|---|
| #25 fixed, `medium-fix-end-to-end` 1.00 | T2, T5 |
| #26 README and fixtures agree | T2 |
| #27 answered with evidence, graders on the robust form or a reason | T1, T3 |
| #28 subfolder verify commands described | T2 |
| Verify passes, SKILL.md at most 160 lines, a reviewer approves | T2, T4 |
