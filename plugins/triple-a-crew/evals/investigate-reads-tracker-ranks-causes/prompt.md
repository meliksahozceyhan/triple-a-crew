---
description: The bug report lives in a mocked Linear. Its description fits two code paths; only the comments (guest account, gift card, coupons.js rollback already tried) say which one. investigate should read the comments, weigh the candidate causes with a confidence and a way to confirm each, note the member-pricing stacking, and edit nothing. The baseline arm gets the same mocked Linear. Needs --scaffold.
tags: [migrated, investigate]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Can you investigate ACT-512 before we fix anything?
