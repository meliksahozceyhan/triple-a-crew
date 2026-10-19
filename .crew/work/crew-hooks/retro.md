# Retro: crew-hooks

**Closed:** 2026-10-19

## What happened
- The hook research came from summarized docs, with the subagent sections only partly quoted (team/T1-researcher.md);
  a $0.03 haiku spike dumped the real payloads before any script depended on them, and the plan held
  (team/T2-engineer.md, decisions.md "Spike confirmed the design")
- The plan ran T3, T4 and T5 in parallel; the organizer gave all four script tasks to one engineer because
  they share JSON parsing and one test runner (decisions.md "One engineer for T3-T6")
- The first status-file path resolution cut paths at a space without `jq` and would have blocked an employee
  that did everything right; reworked before review (team/T3-T6-engineer.md "Rework", board.md)
- Review round 1: 2 must-fix, 6 should-fix, 5 nits, all fixed. Round 2 found a new must-fix (R1: under dash a
  failed redirection on `:` exits 2, which blocks) and four nits, one (R2) caused by a round-1 fix (N5)
  (team/T9-reviewer.md)
- The reviewer ran out of its 40 turns mid-review before writing any finding and had to be resumed
  (findings.md)
- Evals: hooks case 1.00 vs 0.80 without the plugin, organizer suite 5/5, $1.63; not rerun after R1-R5,
  which the model-free tests cover (decisions.md "T10 evals")

## Lessons
| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| L1 | When the docs leave a mechanic open, a cents-cheap live probe settles it before code depends on it | team/T1-researcher.md, team/T2-engineer.md | | `retro.md` only | kept |
| L2 | The reviewer's 40-turn limit runs out on a 9-file review | findings.md | | https://github.com/meliksahozceyhan/triple-a-crew/issues/14 | accepted |
| L3 | Dash-only bugs pass unless dash is installed: `test-hooks.sh` skips its dash half silently without it | team/T9-reviewer.md R1; plugins/triple-a-crew/scripts/test-hooks.sh:354-357 | | `.crew/profile.md` notes | accepted |
| L4 | A second review round found a new must-fix, and one nit came from a round-1 fix | team/T9-reviewer.md | | `retro.md` only | kept |
| L5 | A plan that splits tasks sharing helpers forces overlapping file sets; merge them at planning | decisions.md "One engineer for T3-T6" | | `retro.md` only | kept |

## Proposed text
- **L3** (`.crew/profile.md`, notes, one new bullet): "`sh plugins/triple-a-crew/scripts/test-hooks.sh`
  repeats every case under `dash` only when `dash` is installed, and says nothing otherwise; without it a
  dash-only bug (crew-hooks review R1) passes. Install it with `brew install dash`."
