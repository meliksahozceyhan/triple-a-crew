---
description: Mid-task, the user mentions an unrelated bug they won't fix now and asks a question about the task. No tracker is connected, so the finding should be saved as a local draft. Needs --allow-tools Write.
tags: [trigger, local-draft]
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

Context: I'm adding cursor-based pagination to `GET /users` in our Express API, and that's the only thing this PR should do. While reading the routes I noticed `listOrders` in `src/routes/orders.ts` ignores the `limit` query param entirely and always returns every order; with about 200k orders in prod that endpoint times out. Not touching it in this PR.

Back to pagination: should the cursor encode `(created_at, id)` or just `id`? Our ids are UUIDv4.
