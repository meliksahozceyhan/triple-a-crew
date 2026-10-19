---
description: A size-M fix done end to end, started explicitly so the case tests the employee flow rather than the trigger (starts-work-item-on-large-request covers that). Expects a work item, a reviewer employee on the critical tier, status files, the single verify command run by the organizer itself (not a verifier), no compound shell commands from any agent, real timestamps in status files, and correct RFC 4180 quoting in both writers. Needs --scaffold and --allow-tools Write Edit "Bash(node *)" "Bash(git *)" "Bash(date *)".
tags: [organizer, e2e]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Agent, Bash]
---

/triple-a-crew:work start CSV export breaks when a customer name or note contains a comma, a double quote or a newline. Fix the quoting per RFC 4180 in both the row writer and the header writer, and make sure the tests cover it. The export is a download for our own support team; no other system reads it.
