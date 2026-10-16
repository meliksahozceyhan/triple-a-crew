---
description: test-harden in fill mode adds the risky cases in the project's own framework (node:test) and runs them. Needs --scaffold and --allow-tools Write Edit "Bash(node *)" "Bash(git *)".
tags: [migrated, test-harden]
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

The tests for `collectPages` feel thin. Harden them: find the risky missing cases and add them.
