---
description: The SessionStart hook lists open work items from .crew/work/index.md. Asked not to use tools, Claude names the open item from its session context alone, with no Read, Glob, Grep or Skill call. Without the plugin (baseline) it cannot know. Needs --scaffold.
tags: [hooks]
max_turns: 6
allowed_tools: [Read, Glob, Grep, Skill]
---

Answer in one line and without using any tools: is any crew work item open in this repository, and if so, which one and in what phase?
