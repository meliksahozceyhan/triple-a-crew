---
description: A read-only request that names a ticket. "Investigate SHOP-512 before we fix anything" asks for an investigation, not a change, so the organizer must not start, no work item may be created and no code may change. Claude should still read the issue's comments from the mocked Linear. Fixture and mocks come from the cut investigate case. Needs --scaffold.
tags: [organizer, no-trigger]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Can you investigate SHOP-512 before we fix anything?
