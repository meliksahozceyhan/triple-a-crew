# Notion

Tool names differ between server versions. Match tools by purpose and always read the schema.

## Detect

Notion's MCP server exposes tools such as `notion-search`, `notion-fetch`, `notion-create-pages`,
`notion-update-page` and `notion-create-comment`.

Notion is a tracker only when the team keeps issues in a **database**. Notion being connected is not enough:
find the database (search "issues", "bugs", "tasks", "backlog") and confirm it with the user before treating
it as the tracker, unless the profile names it.

## Where issues go

A database (data source). Take it from the profile (`team`, a database name or ID), otherwise confirm the one
you found.

## Create

Fetch the database first; its schema decides everything.

| Template part | Field | Notes |
|---|---|---|
| Title | the title property | Its name varies: "Name", "Title", "Task" |
| Body | page content | Notion-flavored Markdown |
| Type, priority, labels | select / multi-select / status properties | Only existing options, matched exactly |
| Found while | a URL or relation property, or the body | |

## Search for duplicates

Search within the database for title terms and check each match's status property.

## Comment on an existing issue

Create a comment on the existing page.

## Gotchas

- Property names and option values must match the schema exactly, including case.
- People properties need user IDs; leave them empty unless asked.
- Never create a new database, and never write into a page that is not in the tracker database.
