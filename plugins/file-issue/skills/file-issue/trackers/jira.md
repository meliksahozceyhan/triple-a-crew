# Jira

Tool names differ between servers and versions. Match tools by purpose and always read the schema.

## Detect

- **Atlassian's remote MCP server** exposes tools such as `createJiraIssue`, `searchJiraIssuesUsingJql`,
  `getVisibleJiraProjects`, `getJiraProjectIssueTypesMetadata`, `addCommentToJiraIssue`,
  `getAccessibleAtlassianResources` and `lookupJiraAccountId`. The same server has Confluence tools; ignore them.
- **Community servers** use names such as `jira_create_issue` and `jira_search`.

## Where issues go

A **site** and a **project**.

1. Site: the remote server needs a `cloudId`. Get it from the accessible-resources tool; ask if there are several sites.
2. Project key (such as `ENG`): take it from the profile (`team`), otherwise list visible projects and ask.
3. Issue type: read the project's issue-type metadata and pick an existing type (often Bug, Task or Story).

## Create

| Template part | Field | Notes |
|---|---|---|
| Title | `summary` | |
| Body | `description` | Most MCP tools accept Markdown. If the schema asks for Atlassian Document Format (JSON), build it |
| Destination | `projectKey`, `cloudId` | |
| Type | `issueTypeName` | Must exist in the project |
| Priority | `priority` | Names vary per site (Highest … Lowest); use one from the metadata |
| Labels | `labels` | Free-form strings without spaces |
| Parent | `parent` | Epic or parent issue key, only when the user wants it |
| Found while | issue link | "relates to" link when a link tool exists; otherwise mention the key in the body |

Read the issue type's metadata for **required fields**: projects often add required custom fields (component,
team, environment). Fill them from the profile, or ask; never guess values.

## Search for duplicates

JQL through the search tool:

```
project = ENG AND statusCategory != Done AND text ~ "<term>" ORDER BY updated DESC
```

Escape double quotes inside terms. Repeat with `statusCategory = Done AND resolved >= -30d` to catch regressions.

## Comment on an existing issue

`addCommentToJiraIssue` (or the server's comment tool) with the issue key and body.

## Gotchas

- Issue types, priorities and required fields differ per project; always read metadata first.
- Team-managed projects use `parent` for epics. Older company-managed projects may use an "Epic Link" custom field.
- Assignees need an account ID, not an email; look it up, and only when an assignee was requested.
- Avoid Jira Service Management projects (request types) unless the user names one.
