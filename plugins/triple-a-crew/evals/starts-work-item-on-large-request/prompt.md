---
description: A size-L request (several areas, a format the mobile app depends on). The organizer should open a work item with brief, edge cases, plan and board, then ask for the go-ahead before any engineer starts. Needs --scaffold and --allow-tools Write Edit "Bash(node *)" "Bash(git *)".
tags: [organizer, trigger]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Agent]
---

We need the orders CSV export to be production-ready. Today `exportOrdersCsv` builds one big string and doesn't quote anything. Make it stream rows instead of building the whole file in memory (prod has about 200k orders), quote fields per RFC 4180 (commas, quotes, newlines) in both the header and the rows, and add a `since` date filter. The mobile app parses this export, so the format has to stay compatible. Cover it with tests.
