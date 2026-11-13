---
description: A size-L request that changes how the orders export runs (it builds the whole file in memory and must stream), on a repo with no diagram anywhere. The organizer's plan.md should have a Flow section with a Mermaid task graph, and the message that asks for the go-ahead should show the task graph, the current flow and the final flow with the new or changed nodes marked, the graph agreeing with the plan's dependencies. No engineer starts before the go-ahead. Covers the flow rule (plan.md Flow section, SKILL.md step 5). Needs --scaffold and --allow-tools Write Edit "Bash(node *)" "Bash(git *)" "Bash(date *)".
tags: [organizer, flow]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Agent]
---

The orders CSV export falls over in production: `GET /orders/export` loads every order into memory and builds the whole file as one string before it sends anything, and prod has about 200k orders. Change it so the rows are written to the response as they are read, and add a `since` date filter to the export. The mobile app parses this file, so the columns, their order and the line endings have to stay exactly as they are today. Cover it with tests.
