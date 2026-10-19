# Findings

- 2026-10-19 · actioner-new's `.cursor/skills/session-handoff/SKILL.md:33` hard-codes
  `node .claude/skills/session-handoff/handoff.mjs`; moving actioner-new onto the plugin (W3) breaks that
  path for Cursor · found by T1 researcher · for W3, not filed
