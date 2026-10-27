# Decisions

- **2026-10-19 Do T1-T4 in the main session; staff only the reviewer.** Size M, small text edits across files
  the organizer already has in context; briefing engineers would cost more than the edits. Rejected: an
  engineer per task (overhead), parallel worktrees (the file sets are small and T3 depends on T1/T2).
- **2026-10-19 Fold `plan-review` as a convention check recorded in `decisions.md`, not as a separate review
  pass.** Plain Claude matched the skill (Δ 0.00); what it adds to the organizer is the written trail of which
  rule changed the plan. The skill's output format never matched `plan.md`. Rejected: keeping the skill for
  manual use (Δ 0), copying its whole checklist into the organizer (the stress-test step already covers edge
  cases).
- **2026-10-19 Write the cleanup rules into the verify step instead of pointing at the built-in `simplify`.**
  `simplify` also restructures code for reuse and efficiency, which can change behavior after the engineer's
  acceptance check; the cleanup line only removes noise. Rejected: `simplify` (scope too wide), nothing (Δ 0
  for the skill, but the organizer's own verify step had no noise rule at all).
- **2026-10-19 Keep historical mentions of the cut skills** in the README eval notes and the DESIGN migration
  table and build order; remove them from tables that describe what the plugin ships today.
- **2026-10-19 Read-only requests are not organizer work, even with a ticket key.** The T5 review found that
  "investigate SHOP-512 before we fix anything" matched the old start conditions ("investigation before
  implementation", "reference a ticket") and, once `investigate` was gone, nothing stopped the organizer from
  sizing it M and editing code. The description now names build/change/fix requests, step 2 steps aside on
  investigate/explain/review-only requests, and the cut `investigate` fixture became the no-trigger case
  `stays-out-of-read-only-investigation`. Rejected: keeping `investigate` only as a trigger sink (a skill
  that exists to block another one).
- **2026-10-19 The noise rule applies to the lines this work changed, and convention files win.** Reviewer:
  a whole-file rule would strip pre-existing comments the task never touched (the `medium-fix-end-to-end`
  fixture has some). If a verify check fails on a stripped line, the organizer restores it instead of
  blaming the engineer's task.
- **2026-10-19 Without a profile, the size-L check reads the usual convention files** (`CLAUDE.md`,
  `AGENTS.md`, `CONTRIBUTING.md`, `.claude/rules/`, `.cursor/rules/`, ADR folders), as `plan-review` did.
- **2026-10-19 Drop `plan-review`'s reuse and 10x/100x-scale checklist.** No eval ever measured it, and the
  organizer's stress-test step already covers huge inputs. A judgment call, not a measured regression.
- **2026-10-19 DESIGN's tier rule now allows organizer-only checks.** "Every tier-2 feature is built from
  tier-1 skills" stopped being true; checks too small to earn a skill live in the organizer. `handoff` moved
  to Tier 2 in the DESIGN diagram to match the README (it reads Claude Code transcripts).
- **2026-10-19 Organizer evals not run in this session.** The desktop-app session authenticates through the
  host and the standalone `claude` CLI is not logged in (`claude auth status`: `loggedIn: false`), so
  `claude plugin eval` stops with `partialReason: auth_failed` at $0. The user runs the suite from a logged-in
  terminal; the PR says so.
- **2026-10-19 T5 re-review: ship.** Fixed its follow-ups too: DESIGN "How work starts" now carries the new
  trigger and read-only exclusion (it is a convention file here, so stale wording there would undo the fix);
  README wording matches "the lines it changed"; both READMEs name the stay-out cases that run with a
  baseline; the new case regained the `no-writes` grader so "edits nothing" is checked for Write as well.
- **2026-10-19 Organizer evals ran after the user logged the CLI in** (`claude auth login`): 5/5 cases at
  1.00, one run each, one arm, $1.69, 322 s. `stays-out-of-read-only-investigation` confirms the must-fix
  fix: no Skill call, no Write or Edit, the issue's comments read.
