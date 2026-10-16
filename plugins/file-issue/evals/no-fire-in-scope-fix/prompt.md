---
description: The problem is the task itself, so no issue should be filed.
tags: [no-trigger]
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

I'm fixing `formatPrice` in `src/money.ts` right now: it uses `Math.round`, and finance wants banker's rounding (round half to even) to 2 decimals. That's exactly the bug this PR is for. What's a clean TypeScript implementation that avoids floating-point surprises?
