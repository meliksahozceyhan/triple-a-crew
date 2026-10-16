---
description: A mocked Linear server is connected and there is no profile. The skill should search for duplicates, draft, and ask before creating anything. Delta is not meaningful here (the baseline has no tracker); run with --ablation none.
tags: [mock-tracker]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill]
---

While wiring up the new billing webhook I found that `retryFailedCharges` in `src/billing/retry.ts:88` swallows Stripe `card_declined` errors and marks the charge as paid. That's out of scope for the webhook work. File a follow-up for it in our tracker.
