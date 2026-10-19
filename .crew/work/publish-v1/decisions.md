# Decisions

- **2026-10-19 Publish last.** v1.0.0 should ship the roadmap items that are approved; versions start then.
  Rejected: publishing `file-issue` alone first (possible if you want it sooner; it is the most finished
  plugin).
- **2026-10-19 `version` in each `plugin.json` only.** The docs warn against setting it in both places
  (`plugin.json` silently wins). Tags (`<plugin>--v<version>`) are only required for dependency ranges, but
  `claude plugin tag` checks consistency, so tag every release anyway.
- **2026-10-19 A license file in each plugin folder too.** A Claude chat zip and the Anthropic directory see
  only the plugin folder. Rejected: root only.
- **2026-10-19 Promise Claude chat support for `file-issue` only, until tested.** `onboard`, `test-harden`,
  `work` and `handoff` need files, a shell or subagents. The README's tier-1 claim gets corrected in T3.
- **2026-10-19 Your author email stays a decision, not an automatic fix.** Rewriting history changes every
  SHA and breaks links to PRs #1-#6; keeping it exposes the address. Only you can weigh that.
- **2026-10-19 Plan approved by the user as written.** Runs last, after the other approved items.
