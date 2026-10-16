# Employee protocol

Employees never see the conversation. Everything they need is in the brief, and everything you need back is in
their status file and final report.

## The brief

Write it for a reader who has seen nothing. Fixed sections:

```markdown
# T2: Stream order rows from the query

**Work item:** csv-export · **Role:** engineer · **Model tier:** standard
**Status file:** /abs/path/to/repo/.crew/work/csv-export/team/T2-engineer.md

## Goal
## Why it matters
## Context
- `src/db/orders.js:40` builds the whole result in memory (from T1's report)
- Conventions: CLAUDE.md, .claude/rules/ (from the profile)

## Scope
- In: src/db/orders.js, test/orders.test.js
- Out: everything else. Stop and ask before touching another file.

## Acceptance check
- [ ] Exporting 200k rows stays under 100 MB (new test)
- [ ] `node --test` passes

## Edge cases to cover
- empty table, a field with quotes and newlines
```

## Status file

One file per task, written only by that employee, created first thing and kept current:

```markdown
---
task: T2
role: engineer
model: sonnet
state: in-progress   # in-progress | blocked | done | failed
updated: 2026-10-16T14:05
---
## Progress
- [x] Cursor query
- [ ] Test with 200k rows

## Assumptions
<reversible choices made without asking>

## Questions
<what blocks the task, with the employee's proposed answer>

## Findings
<problems outside the task: what, where (path:line), evidence>
```

## Questions

- **Reversible unknown:** the employee chooses, records it under Assumptions, and continues.
- **Irreversible or out of scope:** the employee sets `state: blocked`, writes the question with a proposed
  answer, and stops. You answer by resuming it with `SendMessage`, or ask the user first.
- You can question any finished employee the same way ("why X?", "what's left?") instead of starting a new
  one that would have to rediscover everything.

## Final report

Every employee ends its run with these sections, in this order:

**Outcome** · **Changed** (files) · **Evidence** (commands run and their results) · **Assumptions** ·
**Open questions** · **Findings**

Employees never file issues, never spawn other agents, and never write under `.claude/`.
