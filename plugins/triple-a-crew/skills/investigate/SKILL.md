---
name: investigate
description: Investigate a bug before anyone fixes it - read the report (from Linear, GitHub, Jira or any connected tracker, a URL, or pasted text), map the symptoms to the code, trace the real flow, and report ranked root-cause hypotheses with path:line evidence, confidence and what would confirm each. Use when the user shares a bug report, ticket ID or URL and asks to investigate, debug, find the root cause, or analyze code paths before fixing. Read-only: it does not fix anything unless asked.
---

# Investigate

Turn a bug report into an evidence-based map of where the bug lives and why. Investigate and explain; do not
fix unless the user asks.

## 1. Read the report

- **Tracker:** use the connected tracker's tools to read the issue and all its comments (Linear, GitHub,
  Jira and others; identify them from tool descriptions). For GitHub without tools:
  `gh issue view <n> --comments`. A pasted report or a URL works too.
- Keep: title, description, status and labels; reproduction steps; expected vs actual; environment hints;
  attachments and linked PRs or issues; and from the comments, clarifications, dead ends already tried, and
  suspected files.
- If you cannot read the issue, say so and ask for the text rather than guessing.

## 2. Form targets

- **Symptom:** what breaks, for whom, under which conditions.
- **Search seeds:** exact error messages, routes, UI copy, job and queue names, model and table names, feature
  flags.
- **Likely layers:** from the repository's real layout (and the notes in `.crew/profile.md`). Never invent
  paths.

## 3. Explore

1. Search for the seeds; open the most relevant files and read their call sites, not just the first hit.
2. Trace the whole flow: user action → client → route or handler → service → storage, queue or external API →
   response.
3. Look for what fits the symptom: wrong filters or units, double application, missing null checks,
   race conditions, stale caches, auth gates, feature flags, timing in syncs.
4. Use `git log` or `git blame` when the report mentions a recent regression.
5. Run searches in parallel; read concrete code over guessing.

## 4. Analyze

For each candidate location: what it does on the happy path, how the reported scenario reaches it, which
branch or data shape produces the bug, how well it matches (high, medium, low), and what would confirm or rule
it out. Rank them: one primary hypothesis plus alternatives.

## 5. Report

```markdown
### Issue snapshot
<id and title · expected vs actual · key comment insights>

### Relevant code
- `path:line` (`symbol`) - why it matters

### Flow walkthrough
1. <how the affected path works today>

### Likely causes
1. **<hypothesis>** - evidence (report + code) - confidence - how to confirm

### Next steps
<which file to change first, which reproduction or test to write>
```

## Rules

- No root cause without code evidence; no "something in the backend".
- Name the runtime or service when several could be involved.
- If the report lacks detail, still map the most plausible paths and list the facts that would narrow them.
- Problems you find that are unrelated to this bug go in a short "Also noticed" list; the `file-issue` skill
  can capture them.
- Inside an organizer work item, a researcher employee returns this same report in its final report.
