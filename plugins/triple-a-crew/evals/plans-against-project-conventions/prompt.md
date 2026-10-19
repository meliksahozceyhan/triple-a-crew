---
description: A size-L request on a repo whose rules live in CONTRIBUTING.md and two ADRs (listed as conventions in the profile), and a naive build would break several of them. At size L the organizer should check the plan against those files and record each rule that changes the plan in decisions.md with the file it comes from, then stop for the go-ahead with no engineer staffed. Covers the convention check (issue #7, step 5). Needs --scaffold and --allow-tools Write Edit "Bash(node *)" "Bash(git *)" "Bash(date *)".
tags: [organizer, conventions]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Agent]
---

We need an invoice list endpoint for the new mobile billing screen: `GET /customers/:id/invoices`, with a filter for invoices above a given amount, a status filter, and paging, because some customers have tens of thousands of invoices. Return each invoice with its amount. The mobile app ships against this response shape, so it has to be right the first time. Cover it with tests.
