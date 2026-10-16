---
description: The mocked Linear search returns an open issue for the same problem. The skill should offer to comment on it instead of creating a duplicate, and do neither without the user's OK. Run with --ablation none.
tags: [mock-tracker]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill]
---

Heads up while I'm on the search feature: `GET /orders` ignores the `limit` query param and returns every row. It timed out again in prod this morning (504 after 30s). Not my task right now. Make sure there's a ticket for it.
