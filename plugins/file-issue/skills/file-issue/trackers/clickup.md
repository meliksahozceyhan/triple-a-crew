# ClickUp

Tool names differ between server versions. Match tools by purpose and always read the schema.

## Detect

ClickUp's MCP server exposes tools such as a task creation tool, a task search or filter tool, a task
comment tool, and a tool that returns the workspace hierarchy.

## Where issues go

Tasks live in a **list**: workspace → space → (folder) → list. Take the list from the profile (`team`),
otherwise read the hierarchy, look for lists named like "Bugs", "Backlog" or "Issues", and ask.

## Create

| Template part | Field | Notes |
|---|---|---|
| Title | `name` | |
| Body | `markdown_description` (or the Markdown field the schema names) | Plain `description` does not render Markdown |
| Destination | list ID | Required |
| Priority | `priority` | `1` urgent, `2` high, `3` normal, `4` low |
| Labels | `tags` | Existing tags in the space |
| Status | `status` | Statuses are per list; leave unset for the list's default |

## Search for duplicates

Search or filter tasks in the workspace by name terms, then narrow to the target list and open statuses.

## Comment on an existing issue

The task comment tool, with the task ID and text.

## Gotchas

- Statuses and custom fields differ per list; read them before setting any.
- Assignees need user IDs; set them only when asked.
