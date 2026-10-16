---
description: The plan breaks four rules from CLAUDE.md and has no acceptance criteria. plan-review should catch them, cite the rules, return a reinforced plan, and change no code. Needs --scaffold.
tags: [migrated, plan-review]
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Before I start, can you sanity-check this plan?

1. Add `GET /invoices` in `src/routes/invoices.js`. It runs `SELECT * FROM invoices WHERE customer_id = ${req.query.customer}` directly on the db connection.
2. Write a small pagination helper inside the route.
3. `npm install csv-stringify` for a CSV variant later.
4. Ship it.
