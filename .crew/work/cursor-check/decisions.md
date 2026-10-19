# Decisions

- **2026-10-19 Promise Cursor support only for `file-issue`, `onboard` and `test-harden`.** They use plain
  `SKILL.md` and relative reference files. `handoff` needs `${CLAUDE_SKILL_DIR}`, `${CLAUDE_SESSION_ID}` and
  Claude Code transcripts; `work` needs the `Agent` tool, plugin-prefixed agent types, model aliases,
  worktrees and `SendMessage`. Rejected: rewriting `handoff` for Cursor now (its value is the transcript
  facts, which Cursor stores differently).
- **2026-10-19 The test is the user's.** Claude cannot type into Cursor (an IDE gets click-only computer
  use). Rejected: trusting the docs alone (the WebFetch summaries may paraphrase, and the plugin route is
  undocumented).
- **2026-10-19 Plan approved by the user as written.**
