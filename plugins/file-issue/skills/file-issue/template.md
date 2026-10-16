# Issue template

Drop a section that has nothing in it, except Problem and Acceptance criteria. Convert the format when the
tracker does not render Markdown (see its tracker file).

```markdown
Title: <the problem in at most 80 characters, not the fix>

## Context
<One or two sentences: which part of the system, and what task was underway when this surfaced.>

## Problem
<What happens, and what should happen instead.>

## Evidence
- Location: `path/to/file.ts:42` (`functionName`)
- <Error text, command and trimmed output, or reproduction steps, in fenced code blocks>

## Impact
<Who or what is affected, how often, how badly. "Unknown" is a valid answer.>

## Suggested approach
<Optional. A starting point, not a decision. Mark unknowns.>

## Acceptance criteria
- [ ] <observable outcome>
- [ ] <test or check that proves it>

## Links
- Found while: <issue, PR or work item>
- Related: <issues>
```

## Local draft file

A local draft (`.crew/issues/<YYYY-MM-DD>-<slug>.md`) adds frontmatter so it can be filed later:

```markdown
---
title: <title>
type: bug            # bug | task | debt | security | ...
priority: medium     # in words, mapped to the tracker's scale when filed
labels: [follow-up]
found: <YYYY-MM-DD>
status: draft        # draft | filed
filed_as:            # issue key and URL once filed
---
<body from the template above, without the Title line>
```
