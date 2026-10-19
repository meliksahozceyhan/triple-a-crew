# Findings

- 2026-10-19 · The eval fixtures are bash scripts (`#!/usr/bin/env bash`, `set -euo pipefail`), while the
  README and DESIGN call the hook scripts POSIX `sh`; fine as long as the harness runs a fixture by its
  shebang, but `pipefail` would fail under a strict `sh` such as dash · found by T4 engineer · not filed
- 2026-10-19 · The eval docs don't say whether `{ source: file, path }` accepts a glob, so graders on a
  work-item file with an unknown id read the `Write` call in the trace instead, which misses later `Edit`s ·
  found by T5b test-engineer · not filed
- 2026-10-19 · The #21 rule makes employees run `date -u` for every status update; eval runs need
  `"Bash(date *)"` in `--allow-tools` (added to the documented commands), and in a user's default permission
  mode it may prompt unless `date` is treated as read-only · found by T5a test-engineer · open for the review
- 2026-10-19 · `medium-fix-end-to-end/fixture.sh` writes a literal newline inside `lines.join("…")` in
  `src/routes/orders.js`, a JavaScript syntax error that predates this work · found by T9 reviewer · not filed
- 2026-10-19 · This session's employees still run the agent definitions loaded at session start (40-turn
  reviewer, no `date -u` rule), so T8 and T9 hit the old limit and T1-T5 wrote invented times; changes to
  agent files apply only after `/reload-plugins` or a new session · found by organizer · not filed
- 2026-10-19 · The verifier is told to run commands from the brief's folder but may not add its own `cd` or
  `&&`; since each subagent Bash call starts in the root, a folder other than the root works only when the
  brief writes `cd <dir> && cmd` (predates this work) · found by T8 reviewer · not filed
