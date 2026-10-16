---
description: The user explicitly asks to log a follow-up. No tracker is connected, so a complete local draft is expected. Needs --allow-tools Write.
tags: [trigger, local-draft]
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

Please log a follow-up for this so it doesn't get lost: our nightly export job (`jobs/export.ts`, function `uploadBatch`) retries failed S3 uploads forever with no backoff. Last night S3 had a blip and the job sent about 40k PUT requests in 10 minutes before someone killed it. I'll pick it up next sprint, not now.
