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

## Regressions to catch
- stops quoting line breaks inside a field
```

`## Regressions to catch` is optional. Add it to a test task on risky work (data, security, money, public API
including consumed file or payload formats, migrations): 3-5 concrete regressions the tests must catch. The
test-engineer shows each one failing on a broken copy outside the repository. Name a copy folder of its own
for the task: `<tmp>/<work-item id>-<task>-copy`, where `<tmp>` is what `node -e
"console.log(require('os').tmpdir())"` prints (`/tmp` without Node), and the exact command that runs the tests
there: a test file path when the runner takes one (`node --test
/var/folders/x/T/csv-export-T3-copy/test/csv.test.js`; Node 22 won't take a folder), otherwise `cd <copy
folder> && <runner>`, which it may run as written. A test task on low-risk work needs no such list.

Every brief also carries this rule for shell commands: run each command alone, as its own Bash call: no pipes,
redirection, `;` or `&&` chains, no `cd` (use absolute paths), and no `echo $?`, `time` or other wrappers of
your own (a command that already contains them, such as `cd web && pnpm test`, runs exactly as listed). Then
the exit code the Bash tool reports is the command's own, and the user's permission rules match the command.
Long output is cut to its start in the reply and saved to a file whose path the tool gives: the employee reads
that file from the end with Read, rather than piping to `tail`. Each Bash call starts in the project root, so
a command for another folder goes into the brief ready to run there: with the tool's own folder flag (`pnpm -C
web test`) or as `cd "web" && pnpm test`, which the employee runs as written.

## Status file

One file per task, written only by that employee, created first thing and kept current:

```markdown
---
task: T2
role: engineer
model: sonnet
state: in-progress   # in-progress | blocked | done | failed
updated: 2026-10-16T14:05:00Z
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

Set `updated` from `date -u +%Y-%m-%dT%H:%M:%SZ` (one plain command) each time the file changes. Never invent
a timestamp.

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
