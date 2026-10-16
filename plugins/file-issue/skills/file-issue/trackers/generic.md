# Any other tracker

Use this when the connected tracker has no file of its own: Shortcut, Azure DevOps, YouTrack, monday.com,
Trello, Plane, Redmine, or something internal. Everything comes from the tools' own schemas.

## Method

1. **Find the create tool.** Its name or description says create, add or save, plus issue, ticket, task,
   story, work item, item or card.
2. **Read its schema.** Note the required fields, which field holds the title and which holds the body, and
   the body format (Markdown, HTML or plain text) from the field description.
3. **Resolve the destination.** Required project, board, team or list IDs come from list or get tools that
   enumerate them. Match against the profile's `team` or the repository name; ask when more than one fits.
4. **Find a search or list tool** for the duplicate check. If there is none, tell the user you could not check.
5. **Find a comment tool** for the duplicate path.
6. **Map the template.** Title to the title field, body to the body field in its format. Set type, priority
   and labels only when the fields exist and their allowed values can be listed.
7. **Never invent** IDs or enum values. Ask instead.

## Notes on common trackers

- **Azure DevOps:** work items with a type from the project's process (Bug, Task, Issue, User Story).
  `System.Title`; `System.Description` is HTML; Bugs put reproduction in `Microsoft.VSTS.TCM.ReproSteps`.
  Area path and iteration path are per project; use the defaults unless told otherwise.
- **Shortcut:** stories with `story_type` `bug`, `feature` or `chore`, a workflow state, and an optional team.
- **monday.com:** items on a board; columns are set by column ID, so read the board's columns first.
- **Trello:** cards in a list on a board; the description is Markdown.
- **YouTrack:** issues in a project; custom fields such as Type and Priority differ per project.
