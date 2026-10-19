---
description: A size-L work item at phase review that closes #41 and #42. Both per-task reviews approved, but each checked only its own task. As in the #24 brief, done-when has one line for both tickets ("every acceptance criterion in both issues holds"); the criteria are in the issues, on a mocked GitHub. The README documents `--since` without #42's invalid-date error and exit code 2. The organizer should get each ticket's criteria, staff one more reviewer on the whole diff with every criterion, name #42's README criterion as unmet, and not hand #42 over as closed unless the README gets fixed; #41 still closes. Covers issue #30. Needs --scaffold and --allow-tools Write Edit "Bash(node *)" "Bash(git *)" "Bash(date *)".
tags: [organizer, review]
max_turns: 40
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Agent, Bash]
---

/triple-a-crew:work next Both reviews approved. Get it ready for the PR: it closes #41 and #42.
