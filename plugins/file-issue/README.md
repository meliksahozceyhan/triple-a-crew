# file-issue

A Claude skill that turns problems found outside the current task into complete follow-up issues, in
whatever tracker you use. It works in Claude Code, and the skill itself is a plain `SKILL.md` that other
Agent Skills hosts can load.

What it does:

1. Decides whether the problem deserves an issue: out of scope, real, not a two-line fix.
2. Finds your tracker: a project profile, then connected MCP tools (Linear, GitHub, Jira, GitLab, Asana,
   ClickUp, Notion, or any other tracker through its tool schemas), then `gh` / `glab`, then a local draft.
3. Gathers context, checks for duplicates, drafts from a template, maps the tracker's fields.
4. Asks before creating anything, then reports the issue key and URL.

## Install

```bash
claude plugin marketplace add meliksahozceyhan/triple-a-crew
claude plugin install file-issue@triple-a-crew
```

## Configure (optional)

Pin a tracker and its defaults in `.crew/profile.md` at the repository root:

```yaml
---
issue_tracker:
  tool: linear          # linear | github | jira | gitlab | asana | clickup | notion | local | another tracker's name
  team: ACT             # Linear team, GitHub owner/repo, Jira project key, GitLab group/project, ...
  labels: [follow-up]
  confirm: always       # always (default) | batch | never
---
```

Without a profile the skill detects the tracker and asks once when there are several.

## Evals

The suite lives in [evals/](evals/) and runs with `claude plugin eval`. Every run is a real model call.

| Case | Checks | Flags it needs |
|---|---|---|
| `implicit-out-of-scope-finding` | Fires on an out-of-scope bug mentioned in passing; saves a local draft; still answers the question | `--allow-tools Write` |
| `explicit-request-no-tracker` | Fires on "log a follow-up"; the draft follows the template | `--allow-tools Write` |
| `no-fire-in-scope-fix` | Stays out when the problem is the task itself | |
| `no-fire-tracker-question` | Stays out of a question about trackers | |
| `linear-confirms-before-creating` | With a mocked Linear: searches for duplicates, drafts, asks before creating | |
| `linear-duplicate-offers-comment` | With a mocked Linear duplicate: offers a comment, creates nothing | |
| `profile-confirm-never-creates` | Profile with `confirm: never`: creates in the profile's team with its label | `--scaffold` |

Tracker cases carry their own mocked Linear server in `<case>/mocks/linear/`, with the real tool schemas in
`_tools.json`. Mocks stay per case on purpose: a suite-wide `evals/mocks/` would give every case a tracker,
including the ones that test the no-tracker path. The baseline arm of a tracker case has no skill to tell
it how to behave, so its delta says little; run these with `--ablation none`.

From this directory:

```bash
# Trigger cases, with the no-plugin baseline
claude plugin eval . --tag trigger no-trigger --allow-tools Write

# Tracker cases, one arm
claude plugin eval . --tag mock-tracker --ablation none --scaffold
```
