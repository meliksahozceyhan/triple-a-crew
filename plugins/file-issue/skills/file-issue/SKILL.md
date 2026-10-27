---
name: file-issue
description: Captures problems outside the current task as follow-up issues so they are not lost. Use proactively, without waiting to be asked, whenever a bug, risk, tech debt or missing piece comes up that will not be fixed in the current change, including one the user mentions in passing while asking about something else ("not touching it in this PR", "out of scope", "later", "someone should look at that") or one you find in code you are not changing. Answer what was asked and also use this skill; only offering to file it is not enough. Also use when the user asks to file, log, open or ticket an issue, bug or follow-up, or hands you findings to turn into issues. Works with Linear, GitHub Issues, Jira, GitLab, Asana, ClickUp, Notion or any tracker reachable through connected tools or a CLI, and falls back to a local draft. Checks for duplicates and asks before creating anything in a tracker. Not for problems being fixed in the current change or already tracked.
---

# File issue

Capture a problem that is outside the current task as an issue someone can act on without this conversation:
in the user's tracker, without duplicates, and only with the user's OK.

Do not let filing derail the current task. When you notice a problem mid-task, note it and file at a natural
pause or when the task is done. Raise it immediately only if it is severe: security, data loss, an outage.
When your reply ends the turn, for example when you answer a question, the end of that reply is the natural
pause: answer first, then capture the problem in the same reply. Never stop at "want me to file this?".

If the user says the problem is already tracked (an issue key or link), do not file it again.

## 1. Decide whether it deserves an issue

Skip this step when the user explicitly asked you to file something.

File only when all three hold:

- **Out of scope.** Fixing it now would widen the current change, or the user said not to touch it.
- **Real.** You have evidence: a code location, an error, a failing command, a reproduction. If you only
  suspect it, check cheaply first (read the code, run the check). If it is still unconfirmed, file it only if
  the user wants, and say in the issue that it is unconfirmed.
- **Not trivial.** If it is a one- or two-line fix in code you are already changing and nobody scoped it out,
  mention it and fix it in the current change instead. Ask if unsure.

**Security problems:** if the repository or tracker is public, do not file a public issue. Tell the user and
suggest the private route instead: a GitHub security advisory, a confidential GitLab issue, or the team's
security process.

## 2. Find the tracker

Take the first option that applies.

1. **Project profile.** If `.crew/profile.md` exists and its frontmatter has `issue_tracker`, use that tool
   and its defaults (format at the end of this file).
2. **Connected tools.** Look through the tools available to you, including deferred tools that a tool-search
   tool can find. Search for "issue", "ticket", "task", "work item" and tracker names: Linear, GitHub, Jira,
   Atlassian, GitLab, Asana, ClickUp, Notion, Shortcut, Azure DevOps, monday, YouTrack, Trello.
   A tracker counts only if it has a tool that creates issues (or tasks, tickets, work items, pages in an
   issues database). Identify it from the tool **descriptions** as well as names: server prefixes are often
   opaque IDs. Then read the matching file in [trackers/](trackers/), or
   [trackers/generic.md](trackers/generic.md) when none matches.
3. **CLI.** If you can run shell commands: `gh` for a GitHub remote, `glab` for a GitLab remote. Check
   `git remote get-url origin` and `gh auth status` / `glab auth status` first. See
   [trackers/github.md](trackers/github.md) and [trackers/gitlab.md](trackers/gitlab.md).
4. **Local draft.** No tracker found: do not ask the user where to file it. Write the issue to
   `<root>/.crew/issues/<YYYY-MM-DD>-<slug>.md`. `<root>` is the git repository root when the working
   directory is inside a repository (`git rev-parse --show-toplevel`), **unless that root is your home
   directory** (some people keep their dotfiles in git): then, and when there is no repository, `<root>` is
   the working directory itself, exactly as your environment reports it. Never write to your home directory
   or to any other parent of the working directory. Tell the user the path and that it can be filed once a
   tracker is connected. If you have no file access (for example in a chat app) or the write is refused, put
   the draft in your reply, ready to paste, and say it was not saved.

If several trackers qualify and no profile picks one, ask the user once which to use, then offer to save the
answer to the profile.

## 3. Gather context

The reader has not seen this conversation. Collect:

- **Where:** repository, branch or commit, `path:line`, function, endpoint or job names.
- **What:** what happens, and what should happen instead.
- **Evidence:** exact error text, the failing command and its trimmed output, log lines, reproduction steps.
- **How it surfaced:** one line on the task that was underway, with a link to its issue or PR if there is one.
- **Impact:** who or what is affected, how often, how badly. Write "unknown" rather than guess.

Never put secrets, tokens, credentials, customer data or personal data in an issue. Redact them.

## 4. Check for duplicates

Search the tracker for open issues about the same problem. Run two or three searches with distinctive terms:
an error-message fragment, a file or function name, an endpoint. Read the closest matches.

- **Same problem, still open:** do not create a new issue. Offer to add a comment with the new evidence.
- **Same problem, recently closed:** it may be a regression. Create the issue and link the old one.
- **Related but different:** create it and link the related issue.

If the tracker has no search tool, say that you could not check for duplicates.

## 5. Draft

Fill in [template.md](template.md).

- **Title:** the problem, not the fix, specific, at most 80 characters. "Orders endpoint ignores the limit
  parameter", not "Fix orders".
- **Body:** self-contained, with `path:line` references and errors in fenced code blocks. Link long logs
  instead of pasting them. It should take a minute to read.
- **Suggested approach** is a starting point, not a decision. Mark what is unknown.
- **Acceptance criteria** are observable and testable.
- **Type and priority** use the tracker's own scale. Be conservative: urgent or highest only for security,
  data loss or an outage.

## 6. Map fields

Read the create tool's schema and the tracker file. Fill required fields from, in order: the profile's
defaults, values you can list from the tracker (teams, projects, labels, issue types), then the user.

- Never invent IDs, label names, issue types, statuses or user names. Use only values that exist.
- Add the profile's default labels, such as `follow-up`.
- Leave the assignee empty unless the user or the profile says otherwise.
- Link the issue to the current task's issue or PR when the tracker supports relations.

## 7. Confirm

Show the user what will be created: the tracker and destination (team, project or repository), the title,
type, priority and labels, and the body (summarize it if it is long). Then ask whether to create it.
This applies even when the user asked you to file it: they asked for an issue, not for this exact text in
this place. The same goes for commenting on an existing issue. A local draft (step 2, option 4) needs no
confirmation: it publishes nothing, so write it and tell the user where it is.

The profile's `confirm` setting decides how:

- `always` (default): ask for each issue.
- `batch`: collect the issues from this pause point into one numbered list and ask once. The user can drop
  or edit items.
- `never`: create without asking. Only when the profile says so explicitly.

If nobody can answer right now (you are a subagent, or the session is non-interactive), create nothing.
End with the draft and the question, or return the drafts to whoever called you.

When the user asks for changes, revise and show only what changed before asking again.

## 8. Create and report

Create the issue with the tracker's tool or CLI. Then:

- Reply with the issue key and URL, one line per issue.
- If the current work has a findings log at `.crew/work/<id>/findings.md`, append one line per issue:
  date, the problem in a few words, key and URL.
- If creation fails, read the error, fix what it names (a missing required field, an unknown label) and
  retry once. If it still fails, save a local draft (step 2, option 4) and tell the user why.

## Profile settings

`file-issue` reads this block from the frontmatter of `.crew/profile.md`:

```yaml
issue_tracker:
  tool: linear          # linear | github | jira | gitlab | asana | clickup | notion | local | another tracker's name
  team: SHOP            # Linear team, GitHub owner/repo, Jira project key, GitLab group/project, Asana project, ClickUp list
  labels: [follow-up]   # added to every issue
  confirm: always       # always | batch | never
```

When you found the tracker by asking the user, offer to write this block to `.crew/profile.md`. Create the
file with only this block if it does not exist, and keep everything else in it if it does.
