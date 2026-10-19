# Plan

From the docs (T1): Cursor loads `SKILL.md` from `.cursor/skills/`, `.agents/skills/` and, for compatibility,
`.claude/skills/` (project and user); it loads agents from `.claude/agents/`; its plugins use
`.cursor-plugin/plugin.json`, and nothing says it reads `.claude-plugin/`. Expected result: `file-issue`,
`onboard` and `test-harden` work; `handoff` and `work` stay Claude Code-only.

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | Research what Cursor loads | read only | done: team/T1-researcher.md | researcher | standard | - |
| T2 | Manual test in Cursor (about 15 minutes, steps 1-7 in T1's status file): skills from `.claude/skills/` and `.cursor/skills/`, implicit `file-issue` trigger, `/onboard`, `test-harden`, `handoff` and `/work status` to see what breaks, the researcher agent, and the plugin route with and without a `.cursor-plugin/plugin.json` | a scratch repo only | results with the Cursor version, written to team/T2-user.md (the organizer writes them from what you report) | user | - | T1 |
| T3 | If T2 shows Cursor installs plugins from `.cursor-plugin/`: add `.cursor-plugin/plugin.json` per plugin and `.cursor-plugin/marketplace.json`, sharing the existing `skills/` and `agents/` folders. Otherwise document the copy or symlink route | .cursor-plugin/**, plugins/*/.cursor-plugin/** (new) or README only | Cursor lists the plugin, or the README route works | engineer | standard | T2 |
| T4 | README: a per-skill Cursor table (works / changes / no) with the tested version and the install route; DESIGN D2 and "Verified mechanics" rows | README.md, docs/DESIGN.md | "not verified yet" gone | engineer | mechanical | T2 |
| T5 | Review; rerun the eval cases of any skill that changed | read only | verdict; changed skills' cases 1.00 | reviewer | critical | T3, T4 |

## T2 manual test steps (about 15 minutes, in a scratch repo)

1. Copy the `file-issue` skill folder into `<scratch>/.claude/skills/`; in Cursor, check that Settings >
   Agents > Third-Party Imports is on. Type `/` in Agent chat: is `file-issue` listed? Move it to
   `.cursor/skills/` and compare.
2. Say "while fixing X I noticed an unrelated bug in Y, nothing tracks it". Does it fire unasked, read
   `trackers/*.md` and `template.md`, and ask before creating?
3. Repeat with `/onboard` (does `.crew/profile.md` get written?) and `test-harden`.
4. Copy `handoff` and run `/handoff`; note which of `${CLAUDE_SKILL_DIR}` and `${CLAUDE_SESSION_ID}` appear
   literally. Copy `work` and run `/work status`: is `$ARGUMENTS` substituted?
5. Copy `plugins/triple-a-crew/agents/researcher.md` to `.claude/agents/`; ask Cursor to "use the researcher
   subagent to find where X is defined". Which model runs it, and can it write files?
6. Put the plugin folder in `~/.cursor/plugins/local/triple-a-crew`, reload the window, open Customize: is it
   listed with only `.claude-plugin/`? Add `.cursor-plugin/plugin.json` with `{"name":"triple-a-crew"}` and
   compare.
7. Note the Cursor version.
