---
description: A second implicit trigger with different wording and stack, so the trigger is not tuned to one prompt. The bug comes up as a side note in a schema question. No tracker is connected. Needs --allow-tools Write.
tags: [trigger, local-draft]
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

This ticket is just adding soft delete to the `invoices` table in our Django app. Side note: while I was in there I saw that `send_reminders()` in `billing/tasks.py` wraps everything in `except Exception: pass`, so when the email provider fails, the reminder silently never goes out. Someone should look at that eventually.

For the soft delete itself: nullable `deleted_at` timestamp, or an `is_deleted` boolean plus a timestamp?
