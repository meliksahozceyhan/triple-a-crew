# Cut plan-review, cleanup and investigate; fold what they add into the organizer

**Size:** M · **Ticket:** none (W1 of handoff `2026-10-16-1720-triple-a-crew-v1-and-roadmap`) · **Opened:** 2026-10-19

## What
Remove the standalone `plan-review`, `cleanup` and `investigate` skills and their eval cases from the
`triple-a-crew` plugin. Keep the parts that still add something by folding them into the organizer:

- `plan-review` → the size-L planning step checks each task against the profile's `conventions` files and
  records every rule that changes the plan, with its file, in `decisions.md`.
- `cleanup` → one line in the verify step: strip debug logs, commented-out code and log-and-rethrow
  try-catch from the changed files, keeping API docs, why-comments and real error handling.
- `investigate` → the ranked-causes report format (confidence and how to confirm, per cause) moves into the
  `researcher` agent.

Then update everything that describes the plugin: root README, plugin README, `docs/DESIGN.md`, and the
stale `description` in `plugins/triple-a-crew/.claude-plugin/plugin.json`.

## Why
The sharpened evals (PR #4) scored Δ 0.00, 0.00 and +0.17 against plain Claude. A skill that plain Claude
matches costs description space and trigger ambiguity for nothing (README "Earn the place").

## Done when
- [ ] The three skill folders and the cases `plan-review-cites-project-rules`,
      `cleanup-stays-in-scope-and-verifies` and `investigate-reads-tracker-ranks-causes` are gone.
- [ ] `grep -rn 'plan-review\|cleanup\|investigate' plugins/` finds only intended mentions.
- [ ] `node --check plugins/triple-a-crew/skills/handoff/handoff.mjs` and `claude plugin validate .` pass
      (only the expected `version` warnings).
- [ ] Organizer evals (`--tag organizer --ablation none --scaffold`, `--runs 1`) score 1.00. (Run by the user:
      the CLI here is not logged in; see decisions.md.)
- [ ] A reviewer has read the diff and every must-fix is resolved.
- [ ] A PR from `cut-no-gain-skills` into `main` is open.

## Constraints
- Profile `conventions`: README.md ("Conventions for new skills": earn the place, short SKILL.md, portable
  frontmatter, no state under `.claude/`), docs/DESIGN.md.
- Evals cost real usage: `--runs 1`, report the cost.
- Plugins are installed from this checkout, so this branch is live in every project after `/reload-plugins`.
- One PR for this phase; the user merges.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| The organizer's description sends "investigate a bug" / "review a plan" / "clean up" to skills that no longer exist | yes | T1: description reworded; step 2 steps aside on read-only requests; case `stays-out-of-read-only-investigation` |
| "Investigate and fix ACT-123" (investigation before implementation) still starts the organizer | yes | T1: description keeps that trigger |
| The verify-step cleanup removes something that matters (JSDoc, a why-comment, a retry) | yes | T1: the line names what to keep |
| The researcher forces the bug-report format onto a non-bug mapping task | yes | T1: format applies only when the brief is a bug |
| The `migrated` eval tag still selects the remaining cases (test-harden, handoff) | yes | T3 docs; T4 grep |
| Eval results table and notes lose the history of why the skills were cut | yes | T3: results rows replaced by a short note |
| Someone types `/triple-a-crew:plan-review` after updating | no, private plugin with one user | PR text |
| actioner-new still has `plan-reinforcer`, `post-plan-cleanup`, `investigate-linear-issue` agents | no | W3 of the handoff |
| Leftover worktree `.claude/worktrees/infallible-saha-9ec6db` holds the old skills | no | W4 of the handoff |
