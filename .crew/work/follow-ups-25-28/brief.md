# Follow-ups #25-#28

**Size:** M · **Tickets:** #25, #26, #27, #28 · **Opened:** 2026-10-19

## What
The four follow-ups filed when `fix-open-issues` closed:
- **#25** `medium-fix-end-to-end/fixture.sh:52` writes a raw newline inside `lines.join("…")`, so
  `src/routes/orders.js` has a syntax error.
- **#26** the eval fixtures are bash scripts (`#!/usr/bin/env bash`, `set -euo pipefail`; the harness runs them
  with `bash`), while the README and DESIGN only say the plugin's scripts are POSIX `sh`.
- **#27** the eval docs don't say whether a grader's `{ source: file, path }` target accepts a glob, so graders
  on work-item files read Write/Edit calls in the trace instead.
- **#28** the verifier may not add its own `cd` or `&&`, and each subagent Bash call starts in the root, so a
  verify command for another folder only works if the brief writes it as `cd <dir> && <cmd>`; nothing tells
  the organizer to.

## Done when
- [ ] #25: `node --check src/routes/orders.js` passes in a fresh scaffold, and `medium-fix-end-to-end` scores 1.00.
- [ ] #26: the README and the fixtures agree on which shell the fixtures need.
- [ ] #27: the README says whether `path` accepts a glob, with evidence; graders on work-item files use the
      more robust form, or a recorded reason why not.
- [ ] #28: the organizer's instructions say how a subfolder verify command goes into the verifier's brief.
- [ ] Profile verify passes; SKILL.md stays at most 160 lines; a reviewer approves.

## Constraints
- README "Conventions for new skills": run every command example; test graders on real trace rows.
- Evals: `--runs 1 --ablation none`, `"Bash(date *)"` in `--allow-tools`, `--keep-temp` where a grader approximates.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| The harness runs fixtures with `bash` today but could change | yes | #26 states it as the requirement, with the evidence |
| A glob that matches several work items (#27) | yes | T1 checks which file a glob target reads |
| A verify command for a folder with spaces in its name (#28) | yes | the example quotes the folder |
| A profile verify command that already has `cd x &&` (#28) | yes | runs as listed (unchanged rule) |
| The deferred S3 grader (test-engineer edits `src/` mid-run) | no | not one of #25-#28; offered to the user |
