---
description: A size-L request (payment webhook retries with new settings) on a repo whose .crew/lessons.md holds one open lesson the request would repeat (a new setting never reaches staging, a fact the code does not show) and one open lesson that has nothing to do with it. The organizer's plan.md should have a Lessons that apply section that names the first, by its id L2 or by the words parameter store, and does not mention the second at all. A plan that lists the unrelated lesson, even to say it does not apply, fails on purpose. The graders read Write and Edit calls of the main session, so an Edit that adds a line under an existing heading without the heading in the same call is not seen. Covers the lessons ledger read at the plan step (formats.md, SKILL.md step 5). Needs --scaffold and --allow-tools Write Edit "Bash(node *)" "Bash(git *)" "Bash(date *)".
tags: [organizer, lessons]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Agent]
---

/triple-a-crew:work start Our outgoing payment webhooks give up after a single attempt, so a partner outage drops payment notices. Make `sendWebhook` retry failed deliveries with exponential backoff: the number of retries and the base delay should be settings (`WEBHOOK_MAX_RETRIES` and `WEBHOOK_BACKOFF_MS`), a 4xx answer other than 429 must not be retried, and every retry has to carry the same `Idempotency-Key` as the first attempt, because the partner counts a repeated key as one payment. Cover it with tests. Lay out the plan and wait for my go-ahead before anyone edits a file.
