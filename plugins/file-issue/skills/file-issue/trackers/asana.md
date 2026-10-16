# Asana

Tool names differ between server versions. Match tools by purpose and always read the schema.

## Detect

Asana's MCP server exposes tools with names such as `asana_create_task`, `asana_search_tasks`,
`asana_typeahead_search`, `asana_get_projects` and a tool for task comments, which Asana calls stories.
Asana has no "issue": an issue is a **task** in a project.

## Where issues go

A **workspace** and a **project** (optionally a section in it). Take the project from the profile (`team`),
otherwise find candidates with typeahead search ("bugs", "backlog", "engineering") and ask.

## Create

| Template part | Field | Notes |
|---|---|---|
| Title | `name` | |
| Body | `html_notes` or `notes` | `notes` is plain text. `html_notes` takes limited HTML wrapped in `<body>`: `<strong>`, `<em>`, `<ul>`, `<ol>`, `<li>`, `<a>`, `<code>`, `<pre>` |
| Destination | `projects`, `workspace` | |
| Labels | `tags` | Existing tags |
| Priority | custom field | Only if the project has a priority custom field; use its existing options |

Convert the template's Markdown: headings become `<strong>` lines, checklists become `<ul>` items.

## Search for duplicates

The full-text task search needs a paid workspace. If it fails, fall back to typeahead search on task names,
or list the project's incomplete tasks and scan titles.

## Comment on an existing issue

Create a story (comment) on the task with the new evidence.

## Gotchas

- Markdown is not rendered; never send raw Markdown in `notes`.
- Custom field values must be existing enum option IDs.
