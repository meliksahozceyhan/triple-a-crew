# Retro: eval-tooling

**Closed:** 2026-11-13

## What happened
- T1 found that no real trace rows existed anywhere in the repository, so the README rule "test a regex
  grader on rows from a real trace" could not be followed. The plan gained one kept eval run (T4)
  (team/T1-researcher.md)
- T2 (the script) and T3 (the cost map) ran in parallel on disjoint files. T3 checked every figure against
  its source and corrected two that T1's report had wrong (team/T3-engineer.md)
- T4: one kept run of `starts-work-item-on-large-request`, score 1.00, $0.41, gave three graders their first
  real rows (decisions.md)
- Verify 4/4 (T6). Review T7: changes requested, two must-fix. The organizer's own near miss for
  `edge-cases-in-brief` removed every wanted word; the real near miss, the brief without its edge-case
  table, passed the grader. So the test found its first wrong grader on its first real rows, and the grader
  was tightened. The script also accepted an empty rows file (team/T7-reviewer.md)
- Recheck T7b: changes requested again, two new must-fix. A self-test added by the fix assumed a macOS home
  folder. Called through a link, the script printed nothing and exited 0; the organizer confirmed that with
  one run. Both were size S, so they were fixed and verify was rerun 4/4, with no third review
  (team/T7b-reviewer.md; decisions.md)

## Lessons
| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| 1 | A near miss removes one thing, the thing the grader is for; removing every wanted word proves nothing | team/T7-reviewer.md must-fix 1 | L3 | `scripts/grader-rows/README.md` and README "Graders match what you mean" (this change), checked by `node scripts/test-graders.mjs` | accepted |
| 2 | The recheck after review fixes found two new must-fix, one caused by a fix | team/T7b-reviewer.md | L1 | `retro.md` only (the recheck rule is the mechanism, and it worked) | kept |
| 3 | A check that can exit 0 without running is worse than no check: the script did nothing when called through a link | team/T7b-reviewer.md N2 | | `.crew/profile.md` note | proposed |
| 4 | A researcher's figures were wrong twice; the engineer who used them checked each against its source | team/T3-engineer.md | | `retro.md` only | kept |

## Proposed text
- **3** (`.crew/profile.md` note): "A verify command must print a last line that says what it checked (`all
  hook tests passed`, `all checked graders behave`), and the verifier's brief asks for that line. Exit code 0
  alone is not evidence: `test-graders.mjs` once exited 0 without running (eval-tooling)."
