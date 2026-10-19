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
- Git has no HTTPS credential helper; push with
  `git -c credential.helper= -c 'credential.helper=!gh auth git-credential' push`.
