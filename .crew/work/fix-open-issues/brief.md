# Fix the open GitHub issues

**Size:** L · **Tickets:** #7, #12, #13, #14, #15, #16, #17, #18, #19, #21, #22 · **Opened:** 2026-10-19

## What
Resolve the eleven open issues in `meliksahozceyhan/triple-a-crew`, all filed from earlier work items' findings
and retros. They change the organizer (`skills/work/`), the five employee agent files, the eval cases and
fixtures, and the README.

| Issue | Change |
|---|---|
| #12 | Organizer and every employee run one plain command per Bash call (no pipes, `;`, `&&`) |
| #13 | Sizing table: a format another system consumes counts as public API |
| #14 | Reviewer records findings as it goes; a turn limit that fits a large review |
| #15 | Eval fixtures refuse to run in a non-empty folder |
| #16 | README: anchor `input_match` path checks on `"file_path"` |
| #17 | `medium-fix-end-to-end` checks that the organizer runs a single verify command itself |
| #18 | Size-L plans map every done-when line to a task (or a recorded deferral) |
| #19 | When a review requests changes, a fresh reviewer checks the fix diff before closing |
| #21 | Status files take `updated` from the clock (`date -u`) |
| #22 | Test-engineer briefs for high-blast-radius work list the regressions the tests must catch |
| #7 | Eval cases for the size-L convention check and the rest of the noise rule |

## Why
Each issue is a gap the crew hit in real work items (crew-hooks, employees-v2, retro-skill, agent-teams-mode).
Fixing them makes the organizer cheaper (fewer prompts and review rounds) and safer (fixtures, re-review).

## Done when
- [ ] Every issue's acceptance criteria hold, or a deferral is recorded in `decisions.md` with the reason.
- [ ] The profile's verify passes: `sh plugins/triple-a-crew/scripts/test-hooks.sh`, `node --check
      plugins/triple-a-crew/skills/handoff/handoff.mjs`, `claude plugin validate .`.
- [ ] The organizer eval suite still scores 1.00, and the new or changed cases pass at `--runs 1`.
- [ ] `SKILL.md` stays about 150 lines (README "Conventions for new skills"); details go to reference files.
- [ ] One PR that closes the issues it resolves.

## Constraints
- Conventions (profile): `README.md` "Conventions for new skills" (earn the place, short SKILL.md, never invent
  values, one eval case per key rule), `docs/DESIGN.md`.
- Evals cost real usage: iterate with `--runs 1 --ablation none`, report cost, run fixtures only in `mktemp -d`.
- Subagent mode and team mode (`teams.md`) must both keep working.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| A profile verify command that itself contains `&&` (#12) | yes | runs as listed, as the verifier already does |
| A command that needs a pipe to be useful (long output) (#12) | yes | read output from a file or with Read instead of `tail` |
| The harness's own files already in the scaffold folder (#15) | yes | T1 research decides the guard's test |
| Someone runs a fixture by hand in the repository root (#15) | yes | the guard exits non-zero, writing nothing |
| Raising `maxTurns` raises worst-case cost (#14) | yes | write-as-you-go first; a modest raise |
| `maxTurns` is ignored for teammates (#14) | yes | teams.md's turn budget already covers it |
| A re-review that itself requests changes (#19) | yes | the loop stops after a second round; the organizer decides |
| Extra opus cost of re-review on every M item (#19) | yes | only when a review requested changes |
| Size-M items, which have no go-ahead (#18) | yes | the mapping is for size L only |
| Placeholder times from haiku employees (#21) | yes | one plain `date -u` command |
| "High blast radius" judged too narrowly or too widely (#22) | yes | tie it to the sizing table's risk list |
| Grading only the organizer's own tool calls (#17) | yes | T1 research |
| A one-turn eval that stops at the size-L go-ahead (#7) | yes | the convention check happens before the go-ahead |
| Flaky judges on long traces (#7, #17) | yes | judge the final reply or files where possible |
| Existing open work items (`cursor-check`, `publish-v1`) | out of scope | unaffected |
