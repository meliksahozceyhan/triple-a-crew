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

A re-staff brief (the ladder in staffing.md) adds `## Earlier attempts`: for each one, its model and effort,
and what it missed, verbatim: the acceptance check and the command output, or the reviewer's must-fix text.
Its status file carries the attempt's letter (`T2b-engineer.md`), so the first attempt's file stays as the
record.

`## Criteria` goes into the last review's brief (SKILL.md step 8): every done-when line of `brief.md`, each
ticket's criteria as written and numbered by ticket (`#41.2` is #41's second). A line that only points at
tickets ("every issue's acceptance criteria hold") is replaced first by those criteria, copied from the
tracker; write them into `brief.md` too. Mark a deferral the user accepted as such. For size L, that review
covers the whole diff against the base. The reviewer reports each line with one of:

| Evidence | Means |
|---|---|
| met | it checked the line itself: a command and its result, or `path:line` |
| pending | only a later task can show it (an eval score, a live test, the user's own test); it names that task |
| as given | it has only another report's word for it (a status file, your summary); never counts as met |
| none | nothing shows that the line holds: a must-fix, or a deferral the user accepts in `decisions.md` |

Before the PR, add the evidence for each `pending` or `as given` line yourself, or treat it as `none`. A
recheck after fixes gets the lines that had `none`, plus every line whose files the fixes touched. A ticket
whose lines are all met is `Closes #N`; one with a line still open is `Refs #N`, with the open lines named,
unless the user says to close it anyway. Name the derived lines in your final report, so the user sees what
a `Closes` rests on.

Every brief also carries this rule for shell commands: run each command alone, as its own Bash call: no pipes,
redirection, `;` or `&&` chains, no `cd` (use absolute paths), and no `echo $?`, `time` or other wrappers of
your own (a command that already contains them, such as `cd web && pnpm test`, runs exactly as listed). Then
the exit code the Bash tool reports is the command's own, and the user's permission rules match the command.
Long output is cut to its start in the reply and saved to a file whose path the tool gives: the employee reads
that file from the end with Read, rather than piping to `tail`. Each Bash call starts in the folder the
session started in (normally the project root), so a command for another folder goes into the brief ready to
run there: with the tool's own folder flag (`pnpm -C web test`) or as `cd "web" && pnpm test`, which the
employee runs as written.

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
