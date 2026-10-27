# Cursor compatibility check

**Size:** M · **Ticket:** none (roadmap, W2 of the v1 handoff) · **Opened:** 2026-10-19

## What
Find out what Cursor loads from these plugins (skills, agents, hooks, the marketplace), test it, and turn
the README's "*Cursor support is not verified yet" into a precise, tested statement per skill, with any small
changes that make tier-1 skills work there.

## Why
The user works in both Claude Code and Cursor (the author's previous project keeps its agents in
`.cursor/agents` with a symlink from `.claude/agents`). DESIGN D2 promises tier-1 skills for Cursor, but
"whether Cursor reads
`SKILL.md` from `.claude/skills` or a plugin" is listed as unconfirmed.

## Done when
- [ ] For each skill (`file-issue`, `onboard`, `test-harden`, `handoff`, `work`): works / works with a change
      / not supported in Cursor, from a real test.
- [ ] An install path for Cursor documented in the README.
- [ ] Any change to a skill keeps it working in Claude Code (its eval cases still pass).

## Constraints
- Conventions (profile): README "Conventions for new skills" (portable frontmatter: `name` and
  `description` only for tier-1 skills).
- Don't modify the author's previous project without asking; never read its `.env*` files.
- The manual Cursor test is the user's (Claude cannot drive Cursor reliably); keep it under 15 minutes.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| Claude Code-only substitutions (`$ARGUMENTS`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PLUGIN_ROOT}`) | yes | T1 research greps them |
| Tool names that differ (`Skill`, `Agent`, `AskUserQuestion`, MCP prefixes) | yes | T1 research |
| Cursor reads the same skill twice (plugin copy and project copy) | yes | install path |
| Cursor version differences | yes | record the tested version |
| Tier-2 organizer in Cursor | no | promised for Claude Code only |
