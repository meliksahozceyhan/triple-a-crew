# GitLab

Tool names differ between servers and versions. Match tools by purpose and always read the schema.

## Detect

- **MCP:** GitLab's own MCP server or a community server, with tools such as `create_issue`, a search or
  `list_issues` tool, and a note/comment tool for issues.
- **CLI:** `glab`, when `glab auth status` succeeds and the repository's remote is on a GitLab host.

## Where issues go

A **project**: its full path (`group/subgroup/project`) or numeric ID. Take it from the profile (`team`),
otherwise from `git remote get-url origin`.

## Create

| Template part | Field | Notes |
|---|---|---|
| Title | `title` | |
| Body | `description` | GitLab-flavored Markdown |
| Destination | project path or ID | |
| Labels | `labels` | Existing labels; scoped labels look like `priority::high` |
| Priority | label | Use the project's priority labels if it has them |
| Type | `issue_type` | `issue`, `incident` or `task` |
| Security | `confidential: true` | Always for security problems |
| Found while | body | `#123` for issues, `!45` for merge requests in the same project |

CLI (`--yes` skips glab's interactive confirmation; confirm with the user before running it):

```bash
glab issue create --repo group/project --title "<title>" --description "$(cat <file>)" --label follow-up --yes
```

Add `--confidential` for security problems.

## Search for duplicates

- **MCP:** the search or list tool, scoped to the project's open issues.
- **CLI:** `glab issue list --repo group/project --search "<terms>"`.

## Comment on an existing issue

- **MCP:** the issue note tool.
- **CLI:** `glab issue note <number> --repo group/project --message "<text>"`.

## Gotchas

- Weight, milestone and iteration exist but leave them unset unless asked.
- Self-managed GitLab instances have their own host; read it from the remote URL.
