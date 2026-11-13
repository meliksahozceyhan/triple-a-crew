---
description: A documentation-only request with several pieces of work (a README rewrite, three reference pages, a CONTRIBUTING section), started explicitly so the organizer opens a work item and writes plan.md. The plan may carry a task graph but must not carry a current flow or a final flow, because no flow changes. A guard that passes on the organizer text before the flow rule and must keep passing after it. The guard looks for a line that starts with Current flow or Final flow, in plain, bold, bulleted or heading form, followed by a Mermaid fence in the same Write or Edit of plan.md, so a label and its diagram split over two Edit calls are not seen, and prose saying there is no flow is allowed. Needs --scaffold and --allow-tools Write Edit "Bash(node *)" "Bash(git *)" "Bash(date *)".
tags: [organizer, flow]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Agent]
---

/triple-a-crew:work start Our docs are stale and new hires keep tripping over them. Documentation only, no code changes: (1) rewrite the README's install and usage sections for the current API (it still shows `parse(text, true)`, which was removed), (2) write one reference page under `docs/` for each of the three modules `parser`, `formatter` and `cache`, from their JSDoc comments and tests, and (3) add a "Running the tests" section to CONTRIBUTING.md. Lay out the plan and wait for my go-ahead before anyone edits a file.
