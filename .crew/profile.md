---
stack: [claude-code-plugins, markdown-skills, node, bash]
verify:
  - sh plugins/triple-a-crew/scripts/test-hooks.sh
  - node --check plugins/triple-a-crew/skills/handoff/handoff.mjs
  - claude plugin validate .
tests: ["plugins/*/evals/**"]
conventions: [README.md, docs/DESIGN.md]
issue_tracker:
  tool: github
  team: meliksahozceyhan/triple-a-crew
  confirm: batch
organizer: proactive
models: {}
---
- A marketplace (`.claude-plugin/marketplace.json`) listing two plugins in `plugins/*`: `file-issue` and
  `triple-a-crew`. They declare no `dependencies` on each other, on purpose (see README Troubleshooting).
- Rules for skills are in README "Conventions for new skills"; design decisions and verified Claude Code
  mechanics are in `docs/DESIGN.md`.
- `claude plugin validate .` warns about missing `version` fields; that is expected while iterating.
- Evals (`claude plugin eval .`, run from a plugin folder) are real model calls on the user's account, so
  they are not in `verify`. Iterate with `--runs 1 --ablation none --case <name>` and report the cost.
- Both plugins are installed at user scope from this checkout: switching branches here changes the plugins in
  every project, and edits apply after `/reload-plugins`.
- Never write under `.claude/`; crew state goes in `.crew/`.
- `sh plugins/triple-a-crew/scripts/test-hooks.sh` repeats every case under `dash` only when `dash` is
  installed, and says nothing otherwise; without it a dash-only bug (crew-hooks review R1) passes. Install it
  with `brew install dash`.
- A running session keeps the agent and skill definitions it loaded at start. After changing a file in
  `plugins/*/agents/` or `plugins/*/skills/`, run `/reload-plugins` before staffing employees, or they follow
  the old text (fix-open-issues: reviewers hit the old 40-turn limit, employees wrote invented timestamps).
- Git has no HTTPS credential helper; push with
  `git -c credential.helper= -c 'credential.helper=!gh auth git-credential' push`.
- A rule here is often stated in several places: `SKILL.md`, `protocol.md` and an agent file (follow-ups-25-28:
  the verifier's folder rule). When one changes, grep the others for the same rule before review.
- Before closing a work item or deleting its branch, confirm the PR is merged with
  `gh pr view <n> --repo meliksahozceyhan/triple-a-crew --json state`; the user may say "merged" before GitHub
  has it (review-24-fixes, follow-ups-25-28).
