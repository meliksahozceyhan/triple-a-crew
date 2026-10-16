---
description: The plan breaks five project rules. Only the pnpm rule is in CLAUDE.md; the others are in CONTRIBUTING.md and two ADRs that .crew/profile.md lists as conventions. plan-review should catch all five, cite each rule's file, return the reinforced plan in its fixed structure (goal, constraints with sources, steps with location and dependencies, risks), and write no code. Needs --scaffold.
tags: [migrated, plan-review]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Before I start, can you sanity-check this plan for the invoices endpoint?

1. Add `GET /invoices` in `src/routes/invoices.js`. It runs `SELECT * FROM invoices WHERE customer_id = ${req.query.customer} LIMIT 50 OFFSET ${req.query.page * 50}` directly on the db connection.
2. Return each invoice with `total: invoice.amount_cents / 100` so the frontend gets dollars.
3. `npm install csv-stringify` for a CSV variant later.
4. Ship it.
