# GitHub Issues

Tool names differ between server versions. Match tools by purpose and always read the schema.

## Detect

- **MCP:** GitHub's MCP server exposes tools such as `issue_write` (with a create method; older versions use
  `create_issue`), `search_issues`, `list_issues`, `issue_read` / `get_issue` and `add_issue_comment`.
- **CLI:** `gh`, when `gh auth status` succeeds and the repository's remote is on GitHub.

## Where issues go

An **owner/repo**. Take it from the profile (`team: owner/repo`), otherwise from `git remote get-url origin`.
File in the repository where the problem lives; never guess a repository.

## Create

| Template part | Field | Notes |
|---|---|---|
| Title | `title` | |
| Body | `body` | GitHub-flavored Markdown |
| Destination | `owner`, `repo` | |
| Labels | `labels` | Only labels that already exist (`gh label list`); do not create new ones unasked |
| Type | `type` | Only if the organization uses issue types |
| Priority | none | Use an existing priority label if the repository has one; otherwise state it in the body |
| Found while | body | "Found while working on #123" or `owner/repo#123` across repositories |

CLI: write the body to a temporary file to avoid quoting problems, then:

```bash
gh issue create --repo owner/repo --title "<title>" --body-file <file> --label follow-up
```

## Search for duplicates

- **MCP:** `search_issues` with `repo:owner/repo is:issue is:open <terms>`.
- **CLI:** `gh issue list --repo owner/repo --state open --search "<terms>"`.

Repeat with `is:closed` to catch regressions of recently closed issues.

## Comment on an existing issue

- **MCP:** `add_issue_comment` with the issue number and body.
- **CLI:** `gh issue comment <number> --repo owner/repo --body-file <file>`.

## Gotchas

- GitHub has no confidential issues. For a security problem in a public repository, do not open an issue;
  suggest a private security advisory instead.
- Labels are silently dropped when the user lacks write access to the repository.
- A parent relationship needs the sub-issues feature; otherwise write "Part of #123" in the body.
