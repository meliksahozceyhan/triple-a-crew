# Work item formats

Everything is under `<root>/.crew/`. Every file has exactly one writer: the organizer writes everything except
`team/`, where each employee writes only its own status file.

```
.crew/
  .gitignore
  work/
    index.md
    <id>/
      brief.md  plan.md  decisions.md  findings.md     committed: the durable record
      board.md  handoff.md  team/<task>-<role>.md      ignored: working state
```

## .crew/.gitignore

```
work/index.md
work/*/board.md
work/*/team/
work/*/handoff.md
```

## index.md

```markdown
# Work items

## Open
- `csv-export` (L) - implement - T3 engineer running - updated 2026-10-16

## Closed
- `orders-limit` (M) - done 2026-10-12
```

## brief.md

```markdown
# <title>

**Size:** L · **Ticket:** ACT-1062 (or none) · **Opened:** 2026-10-16

## What
## Why
## Done when
- [ ] <observable, testable outcome>

## Constraints
<from the profile and the user: stack rules, files not to touch, compatibility promises>

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| 200k rows | yes | T2 streaming + T4 test |
| Field contains a quote | yes | T1 |
| Excel locale separators | no | findings.md |
```

## plan.md

```markdown
# Plan

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | Map how orders are queried | read only | report lists query path with path:line | researcher | standard | - |
| T2 | Stream rows from the query | src/db/orders.js | 200k rows under 100 MB (test) | engineer | standard | T1 |
| T3 | Review T2 | read only | verdict + findings | reviewer | critical | T2 |
```

## board.md

```markdown
# Board: <id>

**Phase:** implement · **Updated:** 2026-10-16T14:05

| Task | Role | Model | State | Status file |
|---|---|---|---|---|
| T1 | researcher | sonnet | done | team/T1-researcher.md |
| T2 | engineer | sonnet | in-progress | team/T2-engineer.md |
| T3 | reviewer | opus | todo | |

**Next:** wait for T2, then staff T3.
```

## decisions.md

```markdown
# Decisions

- **2026-10-16 Stream with a cursor instead of paging with OFFSET.** OFFSET is O(n) per page at 200k rows.
  Rejected: building the CSV in memory (peak memory), a background job (out of scope).
```

## findings.md

```markdown
# Findings

- 2026-10-16 · `listOrders` ignores `limit` (src/routes/orders.js:12) · found by T1 researcher · filed as ACT-1071
```

## handoff.md

```markdown
# Handoff: <id>

**Done:** T1, T2 (verified with `node --test`)
**Next:** staff T3 reviewer on the T2 diff
**Open questions:** <for the user>
```
