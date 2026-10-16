---
description: The project profile pins Linear team ACT with confirm never, so the issue should be created directly with the profile's label. Needs --scaffold. Run with --ablation none.
tags: [mock-tracker, profile]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill]
---

While reviewing the CSV import I noticed `parseRow` in `src/import/csv.ts:57` drops rows whose last column is empty instead of treating it as an empty string, so about 3% of rows vanish silently. Not part of what I'm doing. File it.
