---
description: The handoff skill writes and finalizes a handoff in .crew/handoffs/ (not .claude/handoffs/). Needs --scaffold and --allow-tools Write Edit "Bash(node *)" "Bash(git *)".
tags: [migrated, handoff]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

I'm about to clear the context. Write a handoff so a fresh session can pick this up. The focus for next time: start the CSV export work.
