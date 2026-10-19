# Fix the post-merge review of #24

**Size:** M · **Tickets:** follows #17, #18, #22 (closed by #24) · **Opened:** 2026-10-19

## What
The T12 review of PR #24's merged diff (`.crew/work/fix-open-issues/team/T12-reviewer.md`, git-ignored)
found three issues whose own acceptance criteria are not met, plus gaps a literal reader would fall into.
Fix, as the user chose: M1 (#17 grader can't fail when a verifier is staffed), M2 (#22's "shown" is
unchecked), M3 (#18's coverage isn't shown at the go-ahead), S1 (regression proof has no control run), S2
(one shared copy folder), S4 ("make it and close" skips verify), and the one-line nits N1-N3 and N5-N7.
Record deferrals for S3 and S6.

## Done when
- [ ] M1-M3, S1, S2, S4, N1-N3, N5-N7 fixed; S3 and S6 deferred in decisions.md with the reason.
- [ ] Profile verify passes; SKILL.md stays at most 160 lines.
- [ ] A fresh reviewer approves (one recheck round at most, per SKILL.md step 8).
- [ ] `medium-fix-end-to-end`, `test-engineer-keeps-failing-test` and `starts-work-item-on-large-request`
      score 1.00 at `--runs 1`.

## Constraints
- README "Conventions for new skills": run every command example; test regex graders on real trace rows.
- Evals: `--runs 1 --ablation none`, `"Bash(date *)"` in `--allow-tools`, report cost.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| The eval sandbox denies writes outside the workspace (M2's copy) | yes | the run's `$TMPDIR` is writable (a kept sandbox had `tmp/csv-copy/`); copies go there |
| `node --test <dir>` fails on Node 22 (S1) | yes | examples use a test file path, checked by running it |
| A size-M organizer that runs `node --test` and then staffs a verifier (M1) | yes | a `max: 0` verifier grader |
| An empty coverage table or bare regressions heading (N4) | out of scope | not chosen by the user |
| The organizer's `cd` in team mode (S5) | out of scope | not chosen; stays in T12's file |
