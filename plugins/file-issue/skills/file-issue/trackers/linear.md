# Linear

Tool names differ between server versions. Match tools by purpose and always read the schema.

## Detect

Linear's MCP server (`mcp.linear.app`) exposes tools such as `list_issues`, `get_issue`, `save_issue`
(create and update in one tool; older versions use `create_issue`), `list_teams`, `list_issue_labels`,
`list_projects` and `save_comment` / `create_comment`. Descriptions mention "Linear issue".

## Where issues go

A **team** is required. Take it from the profile (`team`, a name or key such as `ACT`), otherwise list teams
and ask if there is more than one. The team key is the prefix of issue identifiers (`ACT-123`).

## Create

| Template part | Field | Notes |
|---|---|---|
| Title | `title` | |
| Body | `description` | Markdown with literal newlines; do not escape |
| Destination | `team` | Required when creating. Never pass `id` when creating |
| Priority | `priority` | `0` none, `1` urgent, `2` high, `3` medium, `4` low |
| Labels | `labels` | Existing label names; check with the labels tool |
| Found while | `relatedTo`, `links` | `relatedTo` takes issue identifiers; `links` takes `{url, title}` for PRs |
| Parent | `parentId` | Only when the user wants a sub-issue |

Leave `state`, `assignee`, `cycle` and `estimate` unset unless the user or the profile says otherwise: new
issues land in the team's default state, usually Triage or Backlog.

## Search for duplicates

`list_issues` with `query` (searches title and description) and `team`. Check each result's status: Done and
Canceled issues are closed.

## Comment on an existing issue

`save_comment` (or `create_comment`) with `issueId` set to the identifier and `body` in Markdown.

## Gotchas

- `labels` replaces the whole label set on update. On create it is fine; when updating use `addLabels`.
- A team may have issue templates. Use `template` only when the profile names one.
- Linear Markdown supports checklists, so acceptance criteria can stay as `- [ ]` items.
