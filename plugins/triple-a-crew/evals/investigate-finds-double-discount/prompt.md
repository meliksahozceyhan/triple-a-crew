---
description: investigate reads a pasted bug report, traces the flow, and reports the double coupon application in checkout.js with evidence, without editing code. Needs --scaffold.
tags: [migrated, investigate]
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Can you investigate this bug report before we fix anything?

> Customers using coupon SAVE10 get 19% off at checkout instead of 10%. The cart page shows the right total; only the checkout total is wrong. Started after last week's release.
